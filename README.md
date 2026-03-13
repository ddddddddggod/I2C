# I2C
---
*The shift register was implemented as a unified structure without separating RX and TX register. (for Read & Write)
- **Slave** : Implemented with a single FSM, where the number of states was reduced by utilizing flag signals.
- **Slave ver2** : The FSM was divided into two parts: an **I2C protocol FSM** and a **Packet FSM**, while maintaining the same datapath as the Slave module. (Additional test cases were included in the testbench to verify the robustness of the design.)
