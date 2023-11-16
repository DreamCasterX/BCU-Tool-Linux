## A simplified tool works as HP BCU on Linux system


## NOTE: 
### If make/gcc/g++ tools are not pre-installed (e.g., clean OS), install them before running this script.
### On Ubuntu:
```sh
sudo apt update
sudo apt install build-essential 
```


### On RHEL:
```sh
sudo dnf update
sudo dnf groupinstall "Development Tools"
```

### HOW TO USE:
#### Copy the whole 'BCU-Tool-Linux' folder (containing .sh and .tgz files) to HOME directory and run the shell script based on your need::
```sh
cd ~/BCU-Tool-Linux

bash Get_BCU_Only.sh   # To get BCU only
bash Set_BCU_Only.sh   # To set BCU only
bash MPM_Lock.sh  # To lock MPM

```