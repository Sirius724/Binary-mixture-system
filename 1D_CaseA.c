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

/* 랜덤 넘버 관련 전역 변수 */
int streamnum, nstreams, gtype, *stream;

/* 시뮬레이션 물리 파라미터 */
int L = 1000;           // 시스템 크기 (유한 크기 스케일링 검증 시 변경)
int Nrun = 20;          // 앙상블 반복 횟수
int Teq = 10000;        // 열평형(Equilibration) 도달을 위한 MCS
int Tms = 50000;        // 프로파일 측정을 위한 MCS
double T_sim = 2.5;     // 측정 온도 (Tc 이상/이하 조건에 따라 변경)
double kappa = 0.1;     // 유카와 스크리닝 파라미터
double h0_mag = 2.0;    // x=0 위치의 국소적 외부 자기장 강도

/* 동적 할당 배열 및 최적화 변수 */
int *th;
double *spin_profile;
double *spin_profile_mpi;
double *yukawa_table;
int rc;                 // 컷오프 반경

/* 함수 선언 */
void init_yukawa(double kap);
void initial_conf();
void update_metropolis(double Temp);
void measure_profile();

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

    /* 동적 메모리 할당 */
    th = (int *)malloc(L * sizeof(int));
    spin_profile = (double *)malloc(L * sizeof(double));
    spin_profile_mpi = (double *)malloc(L * sizeof(double));
    
    // 유카와 퍼텐셜 룩업 테이블 초기화
    init_yukawa(kappa);

    for(int i = 0; i < L; i++) {
        spin_profile_mpi[i] = 0.0;
    }

    /* 앙상블 루프 시작 */
    for(int irun = 1; irun <= Nrun; irun++)
    {
        initial_conf();

        // 1. 열평형 (Equilibration) 단계 - 측정 없이 시스템 이완
        for (int j = 0; j < Teq; j++) {
            update_metropolis(T_sim);
        }

        // 2. 측정 (Measurement) 단계 - 스핀 프로파일 누적
        for(int j = 0; j < Tms; j++) {
            update_metropolis(T_sim);
            measure_profile();
        }
    } /* end of irun */

    /* 단일 MPI 노드 내에서 시간 및 앙상블 평균 계산 */
    for(int i = 0; i < L; i++) {
        spin_profile[i] = spin_profile[i] / (double)(Tms * Nrun);
    }

    /* 모든 MPI 노드의 데이터를 취합 */
    MPI_Barrier(MPI_COMM_WORLD);
    MPI_Reduce(spin_profile, spin_profile_mpi, L, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
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

        FILE *fp = fopen("data/spin_profile.txt", "w+");
        if (fp == NULL) {
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
        total_s /= (double)L;
        printf("Simulation completed. Profile saved to data/spin_profile.txt\n");
        printf("Average magnetization <s>: %10.6f\n", total_s);
    }

    /* 메모리 해제 및 종료 */
    free(th);
    free(spin_profile);
    free(spin_profile_mpi);
    free(yukawa_table);

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
}

/* 스핀 및 프로파일 초기화 */
void initial_conf()
{
    for(int i = 0; i < L; i++) {
        th[i] = (sprng(stream) < 0.5) ? -1 : 1;
        spin_profile[i] = 0.0;
    }
}

/* 메트로폴리스 업데이트 (유카와 + 국소적 외부 자기장) */
void update_metropolis(double Temp)
{
    for(int kx = 0; kx < L; kx++)
    {
        int X = (int)(sprng(stream) * L);
        double sum_interaction = 0.0;

        // 컷오프 반경 내 이웃들과의 상호작용 계산
        for (int r = 1; r <= rc; r++) {
            int right = X + r;
            if (right >= L) right -= L; // 주기적 경계 조건 우측
            
            int left = X - r;
            if (left < 0) left += L;    // 주기적 경계 조건 좌측

            sum_interaction += (th[right] + th[left]) * yukawa_table[r];
        }

        double dE = 2.0 * th[X] * sum_interaction;

        // x=0 위치에만 강도 h0_mag의 외부 자기장 인가
        if (X == 0) {
            dE += 2.0 * th[X] * h0_mag;
        }

        // 메트로폴리스 수용 확률 계산
        if (dE <= 0.0) {
            th[X] = -th[X];
        } else {
            if (exp(-dE / Temp) > sprng(stream)) {
                th[X] = -th[X];
            }
        }
    }
}

/* 스핀 프로파일 누적 */
void measure_profile()
{
    for(int i = 0; i < L; i++) {
        spin_profile[i] += th[i];
    }
}