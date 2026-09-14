;;; -*- Gerbil -*-
(import (only-in :poo-flow/src/module-system/contribution/interface .o)
        :poo-flow/lambda-episteme/modules/sdlc/config)
(export nasa-7150-2d)
(def nasa-7150-2d
  (.o (:: @ sdlc-nasa-7150-profile) name: 'nasa-7150-2d
      role: 'standard standard: "nasa/npr-7150.2d"
      owner: 'lambda-episteme extends: sdlc-nasa-7150-profile
      runtime-executed: #f))
