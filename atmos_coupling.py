import os
from pathlib import Path
import time

template_name = 'ModernEarthSimple' # WHICH TEMPLATE TO USE

photochem_templates = Path('PHOTOCHEM') / 'INPUTFILES' / 'TEMPLATES'
clima_templates = Path('CLIMA') / 'IO' / 'TEMPLATES'
clima_io = Path('CLIMA') / 'IO'

photo_template = photochem_templates / template_name
clima_template = clima_templates / template_name

photo_ins = Path('PHOTOCHEM/INPUTFILES/')
clima_ins = Path('CLIMA/IO')


def recompile_photo():
    print("\033[32mRecompiling PHOTOCHEM...\033[0m")
    os.system('make -f PhotoMake clean')
    os.system('make -f PhotoMake')

def recompile_clima():
    print("\033[32mRecompiling CLIMA...\033[0m")
    os.system('make -f ClimaMake clean')
    os.system('make -f ClimaMake')

def place_photo_files():
    files_to_copy = [
        ("in.dist", photo_ins / "../in.dist"),
        ("input_photchem.dat", photo_ins / "input_photchem.dat"),
        ("reactions.rx", photo_ins / "reactions.rx"),
        ("parameters.inc", photo_ins / "parameters.inc"),
        ("species.dat", photo_ins / "species.dat"),
        ("PLANET.dat", photo_ins / "PLANET.dat")
    ]
    
    for src, dest in files_to_copy:
        src_path = photo_template / src
        dest_path = dest.resolve()
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        dest_path.write_bytes(src_path.read_bytes())
        print(f"Copied {src} from {photo_template} to {dest_path}")

def place_clima_files():
    src_path = clima_template / "input_clima.dat"
    dest_path = clima_ins / "input_clima.dat"
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    dest_path.write_bytes(src_path.read_bytes())
    print(f"Copied input_clima.dat from {clima_template} to {dest_path}")

def run_photo():
    print("\033[32mRunning PHOTOCHEM...\033[0m")
    start_time = time.time()
    os.system('./Photo.run')
    runtime = time.time() - start_time
    print(f"PHOTOCHEM run time: {runtime:.1f} seconds")
    return runtime

def run_clima():
    print("\033[32mRunning CLIMA...\033[0m")
    start_time = time.time()
    os.system('./Clima.run')
    runtime = time.time() - start_time
    print(f"CLIMA run time: {runtime:.1f} seconds")
    return runtime

def set_photo_coupled(val : int):
    file_path = photo_ins / "input_photchem.dat"
    with open(file_path, 'r') as file:
        lines = file.readlines()
        lines[14] = f"ICOUPLE=   {val}\n"
    with open(file_path, 'w') as file:
        file.writelines(lines)

def set_clima_coupled(val : int):
    file_path = clima_ins / "input_clima.dat"
    with open(file_path, 'r') as file:
        lines = file.readlines()
        lines[21] = f"ICOUPLE=   {val}\n"
    with open(file_path, 'w') as file:
        file.writelines(lines)

def couple_initialization_run():
    print("\033[32mRunning coupled initialization...\033[0m")
    place_photo_files()
    set_photo_coupled(0)
    
    recompile_photo()
    photo_time = run_photo()

    place_clima_files()
    set_clima_coupled(1)

    recompile_clima()
    clima_time = run_clima()

    set_photo_coupled(1)
    return photo_time, clima_time

    