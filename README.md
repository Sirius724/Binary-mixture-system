# Binary Mixture System: Statistical Field Theory and Critical Phenomena

## Project Overview

This research project investigates binary mixture systems using advanced statistical field theory methods. The study bridges microscopic discrete models with macroscopic continuous field theories to provide a rigorous mathematical framework for understanding phase equilibrium and critical phenomena in binary mixtures.

## Research Objectives

1. **Rigorous Mathematical Framework**: Develop exact governing equations from first principles using the Hubbard-Stratonovich transformation
2. **Critical Phenomena Analysis**: Investigate how external fields modulate local critical temperatures in confined geometries
3. **Spatial Heterogeneity Effects**: Analyze order parameter propagation in different geometric configurations (semi-infinite systems, periodic rings)
4. **Finite-Size Scaling**: Derive and validate scaling laws for phase transitions in spatially confined systems
5. **Computational Validation**: Propose Monte Carlo simulations to extend theoretical predictions into the nonlinear regime

## Key Theoretical Components

### Statistical Field Theory Framework

The research employs the **Hubbard-Stratonovich transformation** to decouple particle interactions and introduce an auxiliary order parameter field $\psi(\mathbf{r})$. This mathematical technique enables the conversion of intractable discrete models into tractable field-theoretic formulations.

### Master Equation

The exact non-linear governing equation is:

$$c(-\nabla^2 + \kappa^2)\psi(\mathbf{r}) - \rho_0 \tanh\big[\beta(\psi(\mathbf{r}) + h(\mathbf{r}))\big] = 0$$

This equation captures the equilibrium order parameter distribution without mathematical approximations.

### Ginzburg-Landau Theory

Near the critical point, the theory is expanded to yield the Ginzburg-Landau functional with non-linear coupling terms that demonstrate how external fields shift local critical temperatures:

$$A(\mathbf{r}) = c\kappa^2 - \rho_0\beta + \rho_0\beta^3 h^2(\mathbf{r})$$

The critical $h^2(\mathbf{r})$ term represents symmetry-breaking effects of the external field.

## Analytical Solutions

### Case A: Semi-Infinite Geometry
Exponential penetration of surface-induced order into the bulk:
$$\psi(x) = \psi_s \exp\left( -\frac{x}{\xi} \right)$$

### Case B: Periodic Ring Geometry
Hyperbolic profile reflecting bidirectional order propagation:
$$\psi(x) = \frac{\rho_0 \beta h_0 \xi}{2C \sinh(L/2\xi)} \cosh\left( \frac{L/2 - |x|}{\xi} \right)$$

## Critical Phenomena

### Bulk Critical Temperature
$$T_c = \frac{\rho_0}{k_B c \kappa^2}$$

### Finite-Size Scaling Law
$$T^* \approx T_c \left( 1 + \frac{\text{const}}{L^2} \right)$$

The $1/L^2$ scaling characterizes dimensional restrictions on critical phenomena.

## Model Parameters

| Parameter | Description | Physical Meaning |
|-----------|-------------|------------------|
| $\psi(\mathbf{r})$ | Order parameter field | Compositional or magnetic order |
| $h(\mathbf{r})$ | External field | Surface field or symmetry-breaking perturbation |
| $\kappa$ | Screening parameter | Yukawa potential screening length |
| $\xi$ | Correlation length | Length scale of order fluctuations |
| $\rho_0$ | Density | Number of particles per unit volume |
| $c$ | Gradient coefficient | Interface tension parameter |
| $\beta$ | Inverse temperature | $1/(k_B T)$ |

## Project Structure

```
Binary mixture system/
├── report.tex                          # Main LaTeX research paper
├── README.md                           # This documentation
├── binary_mixture_04.20.tex           # Original detailed derivations
├── setup.sh                            # Bash script for git automation
├── setup.ps1                           # PowerShell script for git automation
├── data/                               # Experimental and calculated data
├── simulations/                        # Monte Carlo simulation codes
├── results/                            # Output data and figures
└── docs/                              # Additional documentation
```

## File Descriptions

### Primary Files
- **report.tex**: Condensed research paper with key theoretical results, analytical solutions, and proposed validation methods
- **binary_mixture_04.20.tex**: Detailed derivations including complete mathematical steps from microscopic to macroscopic descriptions

### Automation Scripts
- **setup.sh**: Bash script that automatically:
  - Initializes git repository
  - Adds updated files to staging
  - Creates comprehensive commit messages
  - Pushes changes to remote repository

- **setup.ps1**: PowerShell version of the automation script for Windows systems

## Nonlinear Extensions

Beyond the linearization approximation, the full Master Equation exhibits:
- **Kink Structures**: Domain wall-like structures when external fields are strong
- **Bistability**: Multiple equilibrium states in certain parameter regimes
- **Hysteresis**: Memory effects during external field cycling

## Proposed Computational Studies

### Monte Carlo Simulation Plan
1. **Validation**: Compare simulations with analytical solutions in linear/nonlinear regimes
2. **Scaling Verification**: Test $1/L^2$ finite-size scaling with various system sizes
3. **Phase Mapping**: Systematically explore parameter space ($\kappa$, $h_0$, $T$)
4. **Nonlinear Characterization**: Study domain formation and critical slowing-down

### Expected Outcomes
- Confirmation of theoretical predictions in the linear regime
- Characterization of nonlinear effects and domain structures
- Validation of finite-size scaling laws
- Phase diagrams for practical parameter ranges

## Mathematical Methods

### Hubbard-Stratonovich Transformation
Decouples particle interactions through auxiliary field introduction, converting intractable partition functions into manageable functional integrals.

### Calculus of Variations
Functional derivatives determine equilibrium order parameter distributions by minimizing the effective free energy.

### Perturbative Expansion
Taylor expansion near the critical point yields the Ginzburg-Landau theory with explicit coefficient mappings to microscopic parameters.

### Asymptotic Analysis
Analytical solutions in limiting cases (semi-infinite systems, periodic boundaries, small fields) provide physical insights and simulation benchmarks.

## Applications

This theoretical framework applies to:
- **Polymer Mixtures**: Phase separation and microphase ordering
- **Colloidal Suspensions**: Particle aggregation and critical phenomena
- **Electrokinetic Systems**: Electric double layer dynamics and surface effects
- **Soft Matter**: Membrane dynamics and domain formation
- **Material Science**: Phase transitions in confined geometries

## Key Publications and References

### Foundational Work
- Hubbard, J. (1959). Calculation of Partition Functions
- Stanley, H. E. (1971). Introduction to Phase Transitions and Critical Phenomena
- Evans, R. (1992). Density Functionals in the Theory of Nonuniform Fluids

### Related Theory
- Privman, V., et al. (1991). Universal Critical-Point Amplitude Relations
- Fisher, M. E. (1974). The Theory of Critical Point Behavior and Phase Transitions

## Installation and Usage

### Generate Project Files

**Linux/Mac:**
```bash
cd /path/to/Binary\ mixture\ system
bash setup.sh
```

**Windows PowerShell:**
```powershell
cd "C:\path\to\Binary mixture system"
.\setup.ps1
```

### Prerequisites
- Git (for version control and automated pushing)
- LaTeX compiler (for compiling report.tex)
- Python (optional, for future simulation codes)

## Setup Instructions

1. **Initialize Repository**: Run `setup.sh` or `setup.ps1`
2. **Configure Git Remote**: 
   ```bash
   git remote add origin <your-repository-url>
   ```
3. **Edit Files**: Modify report.tex and README.md as needed
4. **Commit and Push**: Re-run setup script to automatically update remote

## Contributing

When contributing to this project:
1. Update report.tex with new theoretical results
2. Modify README.md to document changes
3. Run setup script to commit and push changes
4. Include detailed commit messages explaining modifications

## Author

**Jeong Kangeun**
- Changwon National University
- Department: [Department Name]
- Research Focus: Statistical field theory, phase transitions, soft matter systems

## License

This academic research project is part of studies at Changwon National University. For research collaboration or licensing inquiries, please contact the author.

## Acknowledgments

- Advisors and mentors for theoretical guidance
- Computing resources provided by the university
- Colleagues for discussions and feedback

## Contact

For questions, collaboration opportunities, or technical support regarding this research:
- Direct contact: [Your contact information]
- Institution: Changwon National University

## Project Status

- **Current Phase**: Theoretical development and analytical solution derivation
- **Next Phase**: Monte Carlo simulation implementation
- **Future Directions**: Extension to ternary mixtures and experimental validation

## Last Updated

**Date**: April 24, 2026
**Version**: 1.0
**Status**: Active Development

---

*For detailed mathematical derivations, refer to binary_mixture_04.20.tex. For condensed results, see report.tex.*
