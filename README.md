### A simplified tool to operate BIOS stuffs under Linux OS in a quick way


##### [NOTE] 
  + Internet connection is required in order to install missing dependencies
  + BIOS source can be obtained from the BIOS package/Capsule/Linux/xxx_xxxxxx.cab
  + To flash BIOS, put the .cab file to the same directory as this script


### ------------------------------------------------------------------------------
#### [HOW TO USE]
```sh
bash HpBiosCtl.sh  
```
#### [Options]
 - `G` - Get BIOS BCU from the PC
 - `S` - Set BIOS BCU to the PC
 - `B` - Save the fetched BIOS BCU file to an USB drive
 - `M` - Lock Manufacturing Programming Mode
 - `F` - Flash BIOS (local)
 - `L` - Update BIOS with LVFS server (remote)
 - `D` - Decode Feature Byte
 - `R` - Restore the settings to default
 - `Q` - Quit the tool

