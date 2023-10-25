{.compile("/home/john/doc/rep/github.com/stable-diffusion.cpp/stable-diffusion.cpp",
    "-I/home/john/doc/rep/github.com/stable-diffusion.cpp/ggml/include -Ofast").}
{.compile("/home/john/doc/rep/github.com/stable-diffusion.cpp/ggml/src/ggml.c",
    "-I/home/john/doc/rep/github.com/stable-diffusion.cpp/ggml/include/ggml -D_GNU_SOURCE -Ofast").}
{.passC: "-I/home/john/doc/rep/github.com/stable-diffusion.cpp -Ofast".}

import cppstl

type
  SDLogLevel* = enum
    DEBUG, INFO, WARN, ERROR


type
  RNGType* = enum
    STD_DEFAULT_RNG, CUDA_RNG

type
  SampleMethod* = enum
    EULER_A, EULER, HEUN, DPM2, DPMPP2S_A, DPMPP2M, DPMPP2Mv2

type
  Schedule* = enum
    DEFAULT, DISCRETE, KARRAS

type
  StableDiffusion* {.bycopy, header: "stable-diffusion.h", importcpp: "StableDiffusion".} = object
  
proc constructstablediffusion*(nThreads: cint = -1; vaeDecodeOnly: bool = false;
                              freeParamsImmediately: bool = false;
                              rngType: RNGType = STD_DEFAULT_RNG): StableDiffusion {.
    importcpp: "StableDiffusion(@)", constructor.}
proc load_from_file*(this: var StableDiffusion; filePath: CppString; d: Schedule = DEFAULT): bool {.importcpp.}
proc txt2img*(this: var StableDiffusion; prompt: CppString; negativePrompt: CppString;
             cfgScale: cfloat; width: cint; height: cint; sampleMethod: SampleMethod;
             sampleSteps: cint; seed: int64): CppVector[uint8] {.importcpp.}
proc img2img*(this: var StableDiffusion; initImg: CppVector[uint8]; prompt: CppString;
             negativePrompt: CppString; cfgScale: cfloat; width: cint; height: cint;
             sampleMethod: SampleMethod; sampleSteps: cint; strength: cfloat;
             seed: int64): CppVector[uint8] {.importcpp.}
proc setSdLogLevel*(level: SDLogLevel) {.header: "stable-diffusion.h", importc: "set_sd_log_level".} 
