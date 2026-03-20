# I2C
---
*The shift register was implemented as a unified structure without separating RX and TX register. (for Read & Write)
     ![diagram](Slave/slave.png)
- **Slave** : Implemented with a single FSM, where the number of states was reduced by utilizing flag signals.
- **Slave ver2** : The FSM was divided into two parts: an **I2C protocol FSM** and a **Packet FSM**, while maintaining the same datapath as the Slave module. (Additional test cases were included in the testbench to verify the robustness of the design.)
- **Slave ver3** : A period pin was implemented to provide a configurable **hold margin**. The user can adjust the period value through the testbench (TB).
- **Slave ver4** : An additional **overflow pin** was implemented to control the memory buffer behavior when it becomes full. If the overflow pin is 1, a NACK is generated. If it is 0, the buffer performs overwrite operation. This behavior can be selected through the testbench (TB). Additionally, the period logic was modularized.
---
*I removed the optional functions. (hold margin, overflow pin)
     ![diagram](Slave_FIFO_CDC/fifo_cdc.png)
- **Slave FIFO** : Added **RX FIFO** and **TX FIFO** to unify the read and write paths into a single direction (FIFO code sourced from OpenCores). The design uses a single clock.
- **Slave FIFO CDC** : Added a **handshaking CDC** circuit to the FIFO slave design to handle clock domain crossing.
