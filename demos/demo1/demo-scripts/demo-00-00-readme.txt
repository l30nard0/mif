Demos in this directory should be run on network setup described in readme.txt
from previous directory.

Required changes for demo-20* and next ones
- put R2 and S2 network on same virtual network as R1 and S1 (VMnet3)

                  PvD1
                            +------+               +------+
                  P:1::1/48 |      | :10::1 :10::2 |      |
             +------------o-+  R1  +-o--+     +--o-+  S1  |
+--------+   |              |      |     \   /     |      |
|        |   |              +------+      \ /      +------+
| Client +-o-+ VMnet2                      + VMnet3
|        |   |              +------+      / \      +------+
+--------+   |              |      |     /   \     |      |
             +------------o-+  R2  +-o--+     +--o-+  S2  |
                  P:2::1/48 |      | :20::1 :20::2 |      |
                            +------+               +------+
                  PvD2                     <---- Internet ---->