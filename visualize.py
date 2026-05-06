import os
import numpy as np
import matplotlib.pyplot as plt

# --- multi_qsub.sh 에 정의된 파라미터 리스트 ---
T_sim_list = [0.01, 0.02, 0.03, 0.04, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.4, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0]
h0_mag_list = [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0]
kappa_list = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.8, 1.0]

# 데이터가 저장된 폴더와 그래프를 저장할 폴더
DATA_DIR = "data"
PLOT_DIR = "plots"
os.makedirs(PLOT_DIR, exist_ok=True)

def get_filename(prefix, T, h, k):
    """C 코드에서 출력한 파일 이름 포맷(%.3f)에 맞춰 파일 경로 생성"""
    return os.path.join(DATA_DIR, f"{prefix}_T{T:.3f}_h{h:.3f}_k{k:.3f}.txt")

def plot_caseA_all_T(h_val, k_val):
    """
    고정된 h, k 값에 대해 T_sim_list에 있는 모든 온도(T) 데이터(Case A)를 
    하나의 Figure에 3개의 서브플롯으로 시각화합니다.
    """
    plt.figure(figsize=(18, 5))
    colors = plt.cm.viridis(np.linspace(0, 1, len(T_sim_list)))
    
    # 1. 스핀 프로파일(Spin Profile)
    plt.subplot(1, 3, 1)
    for idx, T_val in enumerate(T_sim_list):
        fname = get_filename("CaseA_spin_profile", T_val, h_val, k_val)
        if os.path.exists(fname):
            data = np.loadtxt(fname)
            if data.size > 0:
                plt.plot(data[:, 0], data[:, 1], label=f'T = {T_val}', color=colors[idx])
    plt.xlabel('Position (x)')
    plt.ylabel('Spin Profile <s>')
    plt.title(f'Case A: Spatial Spin Profile (h={h_val}, k={k_val})')
    plt.grid(True, linestyle='--', alpha=0.6)

    # 2. 시간에 따른 자화량(Magnetization vs Time)
    plt.subplot(1, 3, 2)
    for idx, T_val in enumerate(T_sim_list):
        fname = get_filename("CaseA_mag_time", T_val, h_val, k_val)
        if os.path.exists(fname):
            data = np.loadtxt(fname)
            if data.size > 0:
                plt.plot(data[:, 0], data[:, 1], label=f'T = {T_val}', color=colors[idx])
    plt.xlabel('Time (MCS)')
    plt.ylabel('Magnetization')
    plt.title(f'Case A: Magnetization vs Time (h={h_val}, k={k_val})')
    plt.grid(True, linestyle='--', alpha=0.6)

    # 3. 공간 스핀 상관함수(Spin Correlation - 최종 상태)
    plt.subplot(1, 3, 3)
    for idx, T_val in enumerate(T_sim_list):
        fname = get_filename("CaseA_spin_correlation", T_val, h_val, k_val)
        if os.path.exists(fname):
            with open(fname, 'r') as f:
                header = f.readline().strip().split()
            data = np.loadtxt(fname, skiprows=1)
            if data.size > 0 and len(header) > 1:
                r_dist = data[:, 0]
                final_corr = data[:, -1] # 가장 마지막 스냅샷의 상관함수 비교
                plt.plot(r_dist, final_corr, label=f'T = {T_val}', color=colors[idx])
    plt.xlabel('Distance (r)')
    plt.ylabel('Spin Correlation $<s_i s_{i+r}>$')
    plt.title(f'Case A: Final Spin Correlation (h={h_val}, k={k_val})')
    plt.grid(True, linestyle='--', alpha=0.6)
    
    # 범례는 3번째 그래프 우측 바깥에 한 번만 표시
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left', fontsize='small')

    plt.tight_layout()
    save_path = os.path.join(PLOT_DIR, f"CaseA_all_measurements_h{h_val:.3f}_k{k_val:.3f}_all_T.png")
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"Case A 시각화 저장 완료: {save_path}")

if __name__ == "__main__":
    print("Case A 데이터 시각화를 시작합니다...")
    
    # h=2.0, k=0.1 고정 상태에서 모든 온도 데이터 그리기 예시
    plot_caseA_all_T(h_val=2.0, k_val=0.1)