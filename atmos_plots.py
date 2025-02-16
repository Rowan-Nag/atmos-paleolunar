from matplotlib import pyplot as plt
import numpy as np
import pandas as pd
import pathlib

# grab atmos directory
atmos_dir = pathlib.Path(__file__).parent.resolve()
couple_dir = atmos_dir / "COUPLE"

# def get_mixing_ratios():
#     names = ['Argon', 'Methane', 'Ethane', 'Carbon Dioxide', 'Nitrogen', 'Oxygen', 'Hydrogen', 'Nitrogen Dioxide', 'Tropopause layer']
#     numbers = pd.read_csv(couple_dir / 'mixing_ratios.dat', delim_whitespace=True, header=None, usecols=[0]).T
#     numbers.columns = names
#     return numbers

def get_mixing_ratios(**kwargs):
    return pd.read_csv(atmos_dir / 'PHOTOCHEM' / 'PTZ_mixingratios_in.dist', sep="\s+", **kwargs)

def plot_PT():
    pt = get_mixing_ratios(usecols=[0, 1])
    plt.plot(pt['TEMP'], pt['PRESS'])
    plt.yscale('log')
    plt.xlabel('Temperature (K)')
    plt.ylabel('Pressure (bar)') 
    plt.gca().invert_yaxis()
    plt.show()

def plot_ZT():
    zt = get_mixing_ratios(usecols=[1, 2])
    plt.plot(zt['TEMP'], zt['ALT'])
    plt.ylabel('Altitude (km)')
    plt.xlabel('Temperature (K)')
    plt.show()

def plot_mixing_ratio(species):
    mr = get_mixing_ratios()
    plt.plot(mr[species], mr['PRESS'])
    plt.yscale('log')
    plt.ylabel('Pressure')
    plt.xlabel(f'{species} mixing ratio')
    plt.gca().invert_xaxis()
    plt.show()