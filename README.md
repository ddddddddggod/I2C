# I2C
---
*shift register는 rx,tx 따로 나누지 않고 하나로 만들었다.
- Slave : 하나의 FSM으로 만든 모듈. (flag를 활용해 state의 수를 줄임.)
- Slave ver2 : FSM을 I2C protocol FSM과 Packet FSM으로 나눈 모듈. (Datapath는 slave모듈과 동일함.)
   *robust한 design임을 확인하기 위해 testbench에 경우 추가.
