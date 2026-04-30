/**********************************************************************/
/********** 1D Ising-Yukawa Model (Metropolis, Local Field)      ******/
/********** MPI-Version / Random number generator : sprng2.0a    ******/
/********** Measurement : Spatial Spin Profile <s_i>             ******/
/**********************************************************************/

#include "mpi.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <sys/stat.h>
#ifdef _WIN32
#include <direct.h>
#endif
#include "sprng.h"   /* SPRNG header file (Parallel random number generator) */
#include <curand_kernel.h>

/* 랜덤 넘버 관련 전역 변수 */
int streamnum, nstreams, gtype, *stream;

/* 시뮬레이션 물리 파라미터 */
int L = 1000;           // 시스템 크기 (유한 크기 스케일링 검증 시 변경)
int Nrun = 20;          // 앙상블 반복 횟수
int Teq = 10000;        // 열평형(Equilibration) 도달을 위한 MCS
int Tms = 50000;        // 프로파일 측정을 위한 MCS
int N_snap;             // 상관함수 저장을 위한 시간 스냅샷 개수 (동적 계산)
double T_sim = 2.5;     // 측정 온도 (Tc 이상/이하 조건에 따라 변경)
double kappa = 0.1;     // 유카와 스크리닝 파라미터
double h0_mag = 2.0;    // x=0 위치의 국소적 외부 자기장 강도

/* 동적 할당 배열 및 최적화 변수 */
int *th;
double *spin_profile;
double *spin_profile_mpi;
double *yukawa_table;
double *corr_snapshots;    // 시간별 상관함수 앙상블 누적용 (N_snap * L/2)
double *corr_snapshots_mpi;// MPI 취합용
int *snap_times;           // 측정할 시간(MCS) 목록 배열
double *mag_time;          // 시간에 따른 자화량 저장용
double *mag_time_mpi;      // MPI 취합용
int rc;                 // 컷오프 반경

/* CUDA 전용 디바이스(GPU) 메모리 포인터 */
int *d_th;
double *d_corr_snapshots;
double *d_yukawa_table;
curandState *d_rand_states;

/* 함수 선언 */
void init_yukawa(double kap);
void initial_conf();
void update_metropolis(double Temp);
void measure_profile();
void measure_correlation(int jj);

/* CUDA 커널: 메트로폴리스 업데이트 병렬 처리 */
__global__ void update_metropolis_kernel(int *d_th, const double *d_yukawa_table, curandState *states, int L, int rc, double Temp, double h0_mag)
{
    int X = blockIdx.x * blockDim.x + threadIdx.x;

    if (X < L) {
        double sum_interaction = 0.0;

        // 컷오프 반경 내 이웃들과의 상호작용 계산
        for (int r = 1; r <= rc; r++) {
            int right = X + r;
            if (right >= L) right -= L;
            
            int left = X - r;
            if (left < 0) left += L;

            sum_interaction += (d_th[right] + d_th[left]) * d_yukawa_table[r];
        }

        double dE = 2.0 * d_th[X] * sum_interaction;

        if (X == 0) {
            dE += 2.0 * d_th[X] * h0_mag;
        }

        if (dE <= 0.0 || curand_uniform_double(&states[X]) < exp(-dE / Temp)) {
            d_th[X] = -d_th[X];
        }
    }
}

/* CUDA 커널: 상관함수 병렬 계산 (초고속 최적화 버전) */
__global__ void measure_correlation_kernel(const int *__restrict__ d_th, double *__restrict__ d_corr_snapshots, int jj, int L)
{
    int r_dist = blockIdx.x * blockDim.x + threadIdx.x;
    
    if (r_dist < L / 2) {
        int spatial_sum = 0; // 실수(double) 연산 대신 매우 빠른 정수(int) 덧셈 활용
        for (int i = 0; i < L; i++) {
            int j = i + r_dist;
            if (j >= L) j -= L; // 극도로 느린 모듈로(%) 연산을 단순 조건문으로 대체
            spatial_sum += d_th[i] * d_th[j];
        }
        // 스냅샷 인덱스(jj)에 맞춰 GPU 메모리 내에 직접 누적
        d_corr_snapshots[jj * (L / 2) + r_dist] += (double)spatial_sum / (double)L;
    }
}

int main(int argc, char **argv)
{
    int myrank, np;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &myrank);
    MPI_Comm_size(MPI_COMM_WORLD, &np);

    /* 커맨드 라인 인자 파싱 */
    if (argc > 1) T_sim = atof(argv[1]);
    if (argc > 2) h0_mag = atof(argv[2]);
    if (argc > 3) kappa = atof(argv[3]);

    if (myrank == 0) {
        printf("==========================================\n");
        printf("Simulation Parameters:\n");
        printf("T_sim  : %.3f\n", T_sim);
        printf("h0_mag : %.3f\n", h0_mag);
        printf("kappa  : %.3f\n", kappa);
        printf("==========================================\n");
    }

    /* 병렬 랜덤 넘버 초기화 */
    int SEED = time(NULL);
    streamnum = myrank;
    nstreams = np;
    gtype = 0;
    stream = init_sprng(gtype, streamnum, nstreams, SEED, SPRNG_DEFAULT);

    /* 지수 함수적 스냅샷 시간 계산 (10, 20, 40, 80 ...) */
    N_snap = 0;
    int current_t = 10;
    while(current_t <= Tms) {
        N_snap++;
        current_t *= 2;
    }
    snap_times = (int *)malloc(N_snap * sizeof(int));
    current_t = 10;
    for (int i = 0; i < N_snap; i++) {
        snap_times[i] = current_t;
        current_t *= 2;
    }

    /* 동적 메모리 할당 */
    th = (int *)malloc(L * sizeof(int));
    spin_profile = (double *)malloc(L * sizeof(double));
    spin_profile_mpi = (double *)malloc(L * sizeof(double));
    corr_snapshots = (double *)malloc(N_snap * (L / 2) * sizeof(double));
    corr_snapshots_mpi = (double *)malloc(N_snap * (L / 2) * sizeof(double));
    mag_time = (double *)malloc(Tms * sizeof(double));
    mag_time_mpi = (double *)malloc(Tms * sizeof(double));
    
    /* CUDA 디바이스(GPU) 메모리 할당 */
    cudaMalloc((void **)&d_th, L * sizeof(int));
    cudaMalloc((void **)&d_corr_snapshots, N_snap * (L / 2) * sizeof(double));
    cudaMalloc((void **)&d_rand_states, L * sizeof(curandState));
    cudaMemset(d_corr_snapshots, 0, N_snap * (L / 2) * sizeof(double)); // GPU 배열 0으로 초기화

    // 유카와 퍼텐셜 룩업 테이블 초기화
    init_yukawa(kappa);

    for(int i = 0; i < L; i++) {
        spin_profile[i] = 0.0;
        spin_profile_mpi[i] = 0.0;
    }
    for(int i = 0; i < N_snap * (L / 2); i++) {
        corr_snapshots[i] = 0.0;
        corr_snapshots_mpi[i] = 0.0;
    }
    for(int j = 0; j < Tms; j++) {
        mag_time[j] = 0.0;
        mag_time_mpi[j] = 0.0;
    }

    /* 앙상블 루프 시작 */
    for(int irun = 1; irun <= Nrun; irun++)
    {
        initial_conf();

        // 1. 열평형 (Equilibration) 단계 - 측정 없이 시스템 이완
        for (int j = 0; j < Teq; j++) {
            update_metropolis(T_sim);
            
            // 10% 진행될 때마다 출력
            if (myrank == 0 && (j + 1) % (Teq / 10) == 0) {
                printf("  [Run %d] Equilibration : %d / %d steps completed.\n", irun, j + 1, Teq);
            }
        }

        // 2. 측정 (Measurement) 단계 - 스핀 프로파일 누적
        int jj = 0; // 상관함수 스냅샷 인덱스
        int next_snap_time = 10;
        for(int j = 0; j < Tms; j++) {
            update_metropolis(T_sim);
            measure_profile();
            
            // 현재 스텝의 전체 자화량 계산 및 누적
            double current_mag = 0.0;
            for(int i = 0; i < L; i++) current_mag += th[i];
            mag_time[j] += current_mag / (double)L;
            
            // 지수적으로 증가하는 지정된 시간(10, 20, 40...)마다 상관함수 측정 및 누적
            if ((j + 1) == next_snap_time && jj < N_snap) {
                measure_correlation(jj); // 루프 없이 GPU 커널을 호출해 그 안에서 누적
                jj++;
                next_snap_time *= 2;
            }

            // 10% 진행될 때마다 출력
            if (myrank == 0 && (j + 1) % (Tms / 10) == 0) {
                printf("  [Run %d] Measurement   : %d / %d steps completed.\n", irun, j + 1, Tms);
            }
        }
    } /* end of irun */

    /* 모든 앙상블이 완전히 끝난 후, GPU에 누적된 최종 상관함수 데이터를 CPU로 딱 1번만 복사 */
    cudaMemcpy(corr_snapshots, d_corr_snapshots, N_snap * (L / 2) * sizeof(double), cudaMemcpyDeviceToHost);

    /* 단일 MPI 노드 내에서 시간 및 앙상블 평균 계산 */
    for(int i = 0; i < L; i++) {
        spin_profile[i] = spin_profile[i] / (double)(Tms * Nrun);
    }
    for(int i = 0; i < N_snap * (L / 2); i++) {
        corr_snapshots[i] /= (double)Nrun;
    }
    for(int j = 0; j < Tms; j++) {
        mag_time[j] /= (double)Nrun;
    }

    /* 모든 MPI 노드의 데이터를 취합 */
    MPI_Barrier(MPI_COMM_WORLD);
    MPI_Reduce(spin_profile, spin_profile_mpi, L, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
    MPI_Reduce(corr_snapshots, corr_snapshots_mpi, N_snap * (L / 2), MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
    MPI_Reduce(mag_time, mag_time_mpi, Tms, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
    MPI_Barrier(MPI_COMM_WORLD);

    /* 0번 노드에서 결과 파일 저장 */
    if(myrank == 0)
    {
        double total_s = 0.0;
        
            // 데이터 저장 폴더 생성 (이미 존재하면 무시됨)
    #ifdef _WIN32
            _mkdir("data");
    #else
            mkdir("data", 0777);
    #endif

        char fname_profile[256];
        char fname_corr[256];
        char fname_mag[256];
        
        snprintf(fname_profile, sizeof(fname_profile), "data/spin_profile_T%.3f_h%.3f_k%.3f.txt", T_sim, h0_mag, kappa);
        snprintf(fname_corr, sizeof(fname_corr), "data/spin_correlation_T%.3f_h%.3f_k%.3f.txt", T_sim, h0_mag, kappa);
        snprintf(fname_mag, sizeof(fname_mag), "data/mag_time_T%.3f_h%.3f_k%.3f.txt", T_sim, h0_mag, kappa);

        FILE *fp = fopen(fname_profile, "w+");
        FILE *fc = fopen(fname_corr, "w+");
        FILE *fm = fopen(fname_mag, "w+");
        if (fp == NULL || fc == NULL || fm == NULL) {
            printf("Error: Cannot create/open 'data' directory or file.\n");
            MPI_Abort(MPI_COMM_WORLD, 1);
        }

        for(int i = 0; i < L; i++)
        {
            // 노드 개수(np)로 나누어 최종 앙상블 평균 완성
            spin_profile_mpi[i] /= (double)np;
            total_s += spin_profile_mpi[i];
            
            // Plotting의 편의를 위해 원점(x=0)을 중앙으로 정렬 (-L/2 ~ L/2)
            int x_coord = i;
            if (i > L / 2) x_coord = i - L;
            
            fprintf(fp, "%d %10.6f\n", x_coord, spin_profile_mpi[i]);
        }
        fclose(fp);

        // 상관함수 파일 헤더 작성 (각 스냅샷 시간)
        fprintf(fc, "r ");
        for (int jj = 0; jj < N_snap; jj++) {
            fprintf(fc, "MCS_%d ", snap_times[jj]);
        }
        fprintf(fc, "\n");

        for(int i = 0; i < L / 2; i++)
        {
            fprintf(fc, "%d ", i);
            for (int jj = 0; jj < N_snap; jj++) {
                corr_snapshots_mpi[jj * (L / 2) + i] /= (double)np;
                fprintf(fc, "%10.6f ", corr_snapshots_mpi[jj * (L / 2) + i]);
            }
            fprintf(fc, "\n");
        }
        fclose(fc);
        
        for(int j = 0; j < Tms; j++)
        {
            // 노드 개수(np)로 나누어 자화량 앙상블 평균 완성
            mag_time_mpi[j] /= (double)np;
            fprintf(fm, "%d %10.6f\n", j, mag_time_mpi[j]);
        }
        fclose(fm);

        total_s /= (double)L;
        printf("Simulation completed. Profile saved to %s\n", fname_profile);
        printf("Correlation saved to %s\n", fname_corr);
        printf("Magnetization vs Time saved to %s\n", fname_mag);
        printf("Average magnetization <s>: %10.6f\n", total_s);
    }

    /* 메모리 해제 및 종료 */
    free(th);
    free(spin_profile);
    free(spin_profile_mpi);
    free(corr_snapshots);
    free(corr_snapshots_mpi);
    free(snap_times);
    free(mag_time);
    free(mag_time_mpi);
    free(yukawa_table);
    
    /* CUDA 디바이스 메모리 해제 */
    cudaFree(d_th);
    cudaFree(d_yukawa_table);
    cudaFree(d_corr_snapshots);

    MPI_Finalize();
    return 0;
}

/* 유카와 상호작용 컷오프 및 룩업 테이블 생성 */
void init_yukawa(double kap)
{
    rc = (int)(10.0 / kap);       // exp(-10) 수준에서 컷오프
    if (rc > L / 2) rc = L / 2;  // 최대 컷오프는 시스템의 절반 길이로 제한

    yukawa_table = (double *)malloc((rc + 1) * sizeof(double));
    for (int r = 1; r <= rc; r++) {
        yukawa_table[r] = exp(-kap * r);
    }
    cudaMalloc((void **)&d_yukawa_table, (rc + 1) * sizeof(double));
    cudaMemcpy(d_yukawa_table, yukawa_table, (rc + 1) * sizeof(double), cudaMemcpyHostToDevice);
}

/* 스핀 및 프로파일 초기화 */
void initial_conf()
{
    for(int i = 0; i < L; i++) {
        th[i] = (sprng(stream) < 0.5) ? -1 : 1;
    }
}

/* 메트로폴리스 업데이트 (유카와 + 국소적 외부 자기장) */
void update_metropolis(double Temp)
{
    // CPU의 스핀 배열을 GPU로 복사
    cudaMemcpy(d_th, th, L * sizeof(int), cudaMemcpyHostToDevice);
    // CUDA 커널 실행
    int threadsPerBlock = 256;
    int blocksPerGrid = (L + threadsPerBlock - 1) / threadsPerBlock;
    update_metropolis_kernel<<<blocksPerGrid, threadsPerBlock>>>(d_th, d_yukawa_table, d_rand_states, L, rc, Temp, h0_mag);
    // GPU에서 업데이트된 스핀 배열을 다시 CPU로 복사
    cudaMemcpy(th, d_th, L * sizeof(int), cudaMemcpyDeviceToHost);
}

/* 스핀 프로파일 누적 */
void measure_profile()
{
    for(int i = 0; i < L; i++) {
        spin_profile[i] += th[i];
    }
}

/* 스핀 상관 함수 (Spatial Spin Correlation) 누적 - 극한의 GPU 최적화 버전 */
void measure_correlation(int jj)
{
    // 1. 현재 스핀 배열을 호스트(CPU)에서 디바이스(GPU)로 복사
    cudaMemcpy(d_th, th, L * sizeof(int), cudaMemcpyHostToDevice);

    // 2. CUDA 커널 실행 (블록당 256 스레드 구성)
    int threadsPerBlock = 256;
    int blocksPerGrid = (L / 2 + threadsPerBlock - 1) / threadsPerBlock;
    measure_correlation_kernel<<<blocksPerGrid, threadsPerBlock>>>(d_th, d_corr_snapshots, jj, L);
}