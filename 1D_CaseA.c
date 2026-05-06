/**********************************************************************/
/********** 1D Ising-Yukawa Model (Metropolis, Local Field)      ******/
/********** Case A : Semi-infinite System (Open Boundary)        ******/
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

/* 랜덤 넘버 관련 전역 변수 */
int streamnum, nstreams, gtype, *stream;

/* 시뮬레이션 물리 파라미터 */
int L = 1000;           // 시스템 크기 (충분히 커야 무한대 경계처럼 작동)
int Nrun = 20;          // 앙상블 반복 횟수
int Teq = 10000;        // 열평형(Equilibration) 도달을 위한 MCS
int Tms = 50000;        // 프로파일 측정을 위한 MCS
int N_snap;             // 상관함수 저장을 위한 시간 스냅샷 개수 (동적 계산)
double T_sim = 2.5;     // 측정 온도 
double kappa = 0.1;     // 유카와 스크리닝 파라미터
double h0_mag = 2.0;    // x=0 위치의 국소적 외부 자기장 강도

/* 동적 할당 배열 및 최적화 변수 */
int *th;
double *spin_profile;
double *spin_profile_mpi;
double *yukawa_table;
double *corr_snapshots;    // 시간별 상관함수 앙상블 누적용
double *corr_snapshots_mpi;// MPI 취합용
double *temp_corr;         // 각 측정 단계 저장용
int *snap_times;           // 측정할 시간(MCS) 목록 배열
double *mag_time;          // 시간에 따른 자화량 저장용
double *mag_time_mpi;      // MPI 취합용
int rc;                 // 컷오프 반경

/* 함수 선언 */
void init_yukawa(double kap);
void initial_conf();
void update_metropolis(double Temp);
void measure_profile();
void measure_correlation();

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
        printf("Simulation Parameters (Case A: Semi-infinite):\n");
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

    /* 지수 함수적 스냅샷 시간 계산 */
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
    temp_corr = (double *)malloc((L / 2) * sizeof(double));
    mag_time = (double *)malloc(Tms * sizeof(double));
    mag_time_mpi = (double *)malloc(Tms * sizeof(double));
    
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

        // 1. 열평형 (Equilibration) 단계
        for (int j = 0; j < Teq; j++) {
            update_metropolis(T_sim);
            
            if (myrank == 0 && (j + 1) % (Teq / 10) == 0) {
                printf("  [Run %d] Equilibration : %d / %d steps completed.\n", irun, j + 1, Teq);
            }
        }

        // 2. 측정 (Measurement) 단계
        int jj = 0;
        int next_snap_time = 10;
        for(int j = 0; j < Tms; j++) {
            update_metropolis(T_sim);
            measure_profile();
            
            double current_mag = 0.0;
            for(int i = 0; i < L; i++) current_mag += th[i];
            mag_time[j] += fabs(current_mag / (double)L);
            
            if ((j + 1) == next_snap_time && jj < N_snap) {
                measure_correlation(); 
                for (int i = 0; i < L / 2; i++) {
                    corr_snapshots[jj * (L / 2) + i] += temp_corr[i];
                }
                jj++;
                next_snap_time *= 2;
            }

            if (myrank == 0 && (j + 1) % (Tms / 10) == 0) {
                printf("  [Run %d] Measurement   : %d / %d steps completed.\n", irun, j + 1, Tms);
            }
        }
    }

    /* 평균 계산 */
    for(int i = 0; i < L; i++) spin_profile[i] = spin_profile[i] / (double)(Tms * Nrun);
    for(int i = 0; i < N_snap * (L / 2); i++) corr_snapshots[i] /= (double)Nrun;
    for(int j = 0; j < Tms; j++) mag_time[j] /= (double)Nrun;

    /* 모든 MPI 노드의 데이터를 취합 */
    MPI_Barrier(MPI_COMM_WORLD);
    MPI_Reduce(spin_profile, spin_profile_mpi, L, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
    MPI_Reduce(corr_snapshots, corr_snapshots_mpi, N_snap * (L / 2), MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
    MPI_Reduce(mag_time, mag_time_mpi, Tms, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
    MPI_Barrier(MPI_COMM_WORLD);

    /* 결과 파일 저장 */
    if(myrank == 0)
    {
        double total_s = 0.0;
        
#ifdef _WIN32
        _mkdir("data");
#else
        mkdir("data", 0777);
#endif

        char fname_profile[256], fname_corr[256], fname_mag[256];
        
        snprintf(fname_profile, sizeof(fname_profile), "data/CaseA_spin_profile_T%.3f_h%.3f_k%.3f.txt", T_sim, h0_mag, kappa);
        snprintf(fname_corr, sizeof(fname_corr), "data/CaseA_spin_correlation_T%.3f_h%.3f_k%.3f.txt", T_sim, h0_mag, kappa);
        snprintf(fname_mag, sizeof(fname_mag), "data/CaseA_mag_time_T%.3f_h%.3f_k%.3f.txt", T_sim, h0_mag, kappa);

        FILE *fp = fopen(fname_profile, "w+");
        FILE *fc = fopen(fname_corr, "w+");
        FILE *fm = fopen(fname_mag, "w+");

        for(int i = 0; i < L; i++)
        {
            spin_profile_mpi[i] /= (double)np;
            total_s += spin_profile_mpi[i];
            
            // Case A는 원점(x=0)에서 한 방향으로만 뻗어나가므로 0부터 L-1까지 그대로 기록합니다.
            fprintf(fp, "%d %10.6f\n", i, spin_profile_mpi[i]);
        }
        fclose(fp);

        fprintf(fc, "r ");
        for (int jj = 0; jj < N_snap; jj++) fprintf(fc, "MCS_%d ", snap_times[jj]);
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
            mag_time_mpi[j] /= (double)np;
            fprintf(fm, "%d %10.6f\n", j, mag_time_mpi[j]);
        }
        fclose(fm);

        total_s /= (double)L;
        printf("Simulation completed (Case A).\n");
        printf("Profile saved to %s\n", fname_profile);
    }

    /* 메모리 해제 */
    free(th); free(spin_profile); free(spin_profile_mpi);
    free(corr_snapshots); free(corr_snapshots_mpi); free(snap_times);
    free(temp_corr); free(mag_time); free(mag_time_mpi); free(yukawa_table);

    MPI_Finalize();
    return 0;
}

void init_yukawa(double kap)
{
    rc = (int)(10.0 / kap);       
    if (rc > L / 2) rc = L / 2;  

    yukawa_table = (double *)malloc((rc + 1) * sizeof(double));
    for (int r = 1; r <= rc; r++) yukawa_table[r] = exp(-kap * r);
}

void initial_conf()
{
    for(int i = 0; i < L; i++) th[i] = (sprng(stream) < 0.5) ? -1 : 1;
}

void update_metropolis(double Temp)
{
    for(int kx = 0; kx < L; kx++)
    {
        int X = (int)(sprng(stream) * L);
        double sum_interaction = 0.0;

        for (int r = 1; r <= rc; r++) {
            int right = X + r;
            int left = X - r;
            
            // Case A: 열린 경계 조건 (Open Boundary Condition)
            // 범위를 벗어난 이웃은 상호작용에서 제외 (wrap-around 금지)
            if (right < L) sum_interaction += th[right] * yukawa_table[r];
            if (left >= 0) sum_interaction += th[left] * yukawa_table[r];
        }

        double dE = 2.0 * th[X] * sum_interaction;

        if (X == 0) dE += 2.0 * th[X] * h0_mag; // x=0 표면에만 국소 자기장

        if (dE <= 0.0 || exp(-dE / Temp) > sprng(stream)) {
            th[X] = -th[X];
        }
    }
}

void measure_profile()
{
    for(int i = 0; i < L; i++) spin_profile[i] += th[i];
}

void measure_correlation()
{
    int r_dist, i;
    for(r_dist = 0; r_dist < L / 2; r_dist++) 
    {
        int spatial_sum = 0; 
        int count = 0;
        for(i = 0; i < L; i++)
        {
            int j = i + r_dist;
            // Case A: 열린 경계 조건이므로 j가 L을 넘어가면 통계에서 제외
            if (j < L) { 
                spatial_sum += th[i] * th[j];
                count++;
            }
        }
        temp_corr[r_dist] = count > 0 ? (double)spatial_sum / (double)count : 0.0;
    }
}