#!/bin/bash

echo "Keep the camera loaded"
switchrelais[${relaisnamepin["Kameraladegerät"]}]=1

echo "Lüfter ein"
switchrelais[${relaisnamepin["Lüfter"]}]=1
