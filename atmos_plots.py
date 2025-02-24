from matplotlib import pyplot as plt
import numpy as np
import pandas as pd
import pathlib

# grab atmos directory
atmos_dir = pathlib.Path(__file__).parent.resolve()
couple_dir = atmos_dir / "COUPLE"


def get_mixing_ratios(**kwargs):
    return pd.read_csv(atmos_dir / 'PHOTOCHEM' / 'PTZ_mixingratios_in.dist', sep="\s+", **kwargs)

def get_clima_out():
    'Gets altitude, temperature, and water mixing ratio from COUPLE/fromClima2Photo.dat'
    return pd.read_csv(couple_dir / 'fromClima2Photo.dat', sep="\s+", header=None, usecols=[0, 1, 2], names=['ALT', 'TEMP', 'H2O'])

def get_clima_tempOut():
    'Gets temperature from CLIMA/IO/tempIn.dat'
    return pd.read_csv(atmos_dir / 'CLIMA' / 'IO' / 'TempOut.dat', sep="\s+", header=None, names=['TEMP', 'ALT'])

def get_fromPhoto2Clima():
    # altitude, pressure, O3, H2O, CH4, CO2, C2H6
    return pd.read_csv(couple_dir / 'fromPhoto2Clima.dat', sep="\s+", header=None, names=['ALT', 'PRES', 'O3', 'CH4', 'CO2', 'C2H6'])

def plot_clima_tempOut():
    profile = get_clima_tempOut()
    plt.plot(profile['TEMP'], profile['ALT'])
    plt.xlabel('Temperature (K)')
    plt.ylabel('Altitude')
    # plt.show()

def plot_PT(mx = None):
    if mx is None:
        mx = get_mixing_ratios(usecols=[0, 1])
    plt.plot(mx['TEMP'], mx['PRESS'])
    plt.yscale('log')
    plt.xlabel('Temperature (K)')
    plt.ylabel('Pressure (bar)') 
    plt.gca().invert_yaxis()
    # plt.show()

def plot_ZT(mx = None):
    if mx is None:
        mx = get_mixing_ratios(usecols=[1, 2])
    zt = get_mixing_ratios(usecols=[1, 2])
    plt.plot(zt['TEMP'], zt['ALT'])
    plt.ylabel('Altitude (km)')
    plt.xlabel('Temperature (K)')
    # plt.show()

def plot_mixing_ratio(species, mx=None):
    if mx is None:
        mx = get_mixing_ratios()
    plt.plot(mx[species], mx['PRESS'])
    plt.yscale('log')
    plt.ylabel('Pressure')
    plt.xlabel(f'{species} mixing ratio')
    plt.gca().invert_xaxis()
    # plt.show()