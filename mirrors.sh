#!/bin/bash

set -e

date

# export HTTP_PROXY=proxy.codingcafe.org:8118
[ $HTTP_PROXY ] && export HTTPS_PROXY=$HTTP_PROXY
[ $HTTP_PROXY ] && export http_proxy=$HTTP_PROXY
[ $HTTPS_PROXY ] && export https_proxy=$HTTPS_PROXY

export ROOT=/var/mirrors

mkdir -p $ROOT
cd $_

[ $# -ge 1 ] && export PATTERN="$1"

parallel --bar --group --shuf -j 10 'bash -c '"'"'
set -e
export ARGS={}"  "
xargs -n1 <<< "$ARGS"
[ $(xargs -n1 <<< {} | wc -l) -ne 3 ] && exit 0
export SRC_SITE="$(cut -d" " -f1 <<< "$ARGS")"
export SRC_DIR="$(cut -d" " -f3 <<< "$ARGS")"
export SRC="$SRC_SITE$SRC_DIR.git"
export DST_DOMAIN="$(cut -d" " -f2 <<< "$ARGS" | sed "s/^\/*//" | sed "s/\/*$//")"
export DST_SITE="git@git.codingcafe.org:Mirrors/$DST_DOMAIN"
export DST_DIR="$SRC_DIR"
export DST="$DST_SITE$DST_DIR.git"
export LOCAL="$(pwd)/$DST_DIR.git"

echo "[\"$DST_DIR\"]"

if [ ! "'"$PATTERN"'" ] || grep "'"$PATTERN"'" <<< "$SRC_DIR"; then
    mkdir -p "$(dirname "$LOCAL")"
    cd "$(dirname "$LOCAL")"
    [ -d "$LOCAL" ] || git clone --mirror "$DST" "$LOCAL" 2>&1 || git clone --mirror "$SRC" "$LOCAL" 2>&1
    cd "$LOCAL"
    git remote set-url origin "$DST" 2>&1
    git fetch --all 2>&1 || true
    [ "$(git lfs ls-files)" ] && git lfs fetch --all 2>&1 || true
    git remote set-url origin "$SRC" 2>&1
    git fetch --prune --all 2>&1
    # [ "$(git lfs ls-files)" ] && git lfs fetch --prune --all 2>&1
    [ "$(git lfs ls-files)" ] && git lfs fetch --all 2>&1
    git gc --auto 2>&1
    git remote set-url origin "$DST" 2>&1
    [ "$(git lfs ls-files)" ] && git lfs push --all origin 2>&1 || true
    git push --mirror origin 2>&1
fi
'"'" ::: {\
https://github.com/\ /\ {\
01org/{mkl-dnn,processor-trace,tbb},\
abseil/abseil-{cpp,py},\
afq984/python-cxxfilt,\
agauniyal/{rang,termdb},\
aquynh/capstone,\
ARM-software/{arm-trusted-firmware,ComputeLibrary,lisa},\
asmjit/{asm{db,jit,tk},cult},\
aws/aws-{cli,sdk-{cpp,go,java,js,net,php,ruby}},\
axel-download-accelerator/axel,\
benjaminp/six,\
boostorg/boost,\
BVLC/caffe,\
c-ares/c-ares,\
caffe2/{caffe2,models},\
catchorg/{Catch2,Clara},\
ccache/ccache,\
cocodataset/{cocoapi,panopticapi},\
containerd/containerd,\
cython/cython,\
dmlc/{dlpack,dmlc-core,gluon-cv,gluon-nlp,HalideIR,tvm,xgboost},\
docker/docker-ce,\
docopt/docopt,\
dotnet/{cli,core{,-setup,clr,fx},standard},\
eigenteam/eigen-git-mirror,\
emil-e/rapidcheck,\
envoyproxy/{data-plane-api,envoy,{go,java}-control-plane,nighthawk,protoc-gen-validate},\
facebook/{rocksdb,zstd},\
facebookincubator/{fbjni,gloo},\
facebookresearch/{ClassyVision,CrypTen,Detectron,detectron2,dlrm,DrQA,faiss,fastMRI,fastText,flashlight,fvcore,habitat-sim,ImageNet-Adversarial-Training,maskrcnn-benchmark,ParlAI,pycls,pytext,pythia,PyTorch-BigGraph,pytorch-dp,pytorch3d,SentEval,ResNeXt,wav2letter,XLM},\
FFmpeg/FFmpeg,\
fmtlib/{fmt,format-benchmark},\
frerich/clcache,\
Frozenball/pytest-sugar,\
gabime/spdlog,\
gflags/gflags,\
giampaolo/psutil,\
github/{git-lfs,gitignore},\
golang/{appengine,benchmarks,dep,example,freetype,glog,go{,frontend},groupcache,leveldb,mock,oauth2,protobuf,snappy,term,winstrap},\
goldmann/docker-squash,\
google/{benchmark,bloaty,boringssl,flatbuffers,gemmlowp,glog,googletest,jax,leveldb,nsync,protobuf,re2,skia,snappy,upb,XNNPACK},\
googleapis/googleapis,\
googlefonts/{fontmake,noto-{cjk,emoji,fonts,sans-hebrew,source},nototools,robotoslab},\
grpc/grpc{,-{dart,dotnet,go,java,node,php,proto,swift,web}},\
halide/Halide,\
harfbuzz/harfbuzz,\
houseroad/foxi,\
HowardHinnant/date,\
huggingface/{knockknock,Mongoku,neuralcoref,pytorch-{openai-transformer-lm,pretrained-BigGAN},swift-coreml-transformers,tflite-android-transformers,tokenizers,torchMoji,transformers},\
HypothesisWorks/hypothesis,\
iina/{iina{,-plugin-definition,-website},plugin-ytdl},\
intel/{ARM_NEON_2_x86_SSE,compute-runtime,ideep,mkl-dnn},\
intelxed/xed,\
IvanKobzarev/fbjni,\
JDAI-CV/{dabnn{,-example},DCL,DNNLibrary},\
jemalloc/jemalloc,\
jordansissel/fpm,\
JuliaStrings/utf8proc,\
Kitware/{CMake,VTK},\
lemire/simdjson,\
libav/libav,\
libuv/libuv,\
llvm/llvm-{archive,project,test-suite,www{,-pubs}},\
llvm-mirror/{ll{vm,d,db,go},clang{,-tools-extra},polly,compiler-rt,openmp,lib{unwind,cxx{,abi}},test-suite},\
LMDB/lmdb,\
lutzroeder/netron,\
madler/zlib,\
matplotlib/{jupyter-matplotlib,matplotlib,mplcairo,pytest-mpl},\
Maratyszcza/{confu,cpuinfo,FP16,FXdiv,NNPACK,PeachPy,psimd,pthreadpool},\
micheles/{decorator,plac},\
Microsoft/{azure-pipelines-yaml,BuildXL,calculator,cascadia-code,CNTK,cppwinrt,dotnet,GSL,LightGBM,mimalloc,msbuild,{,Delayed-Compensation-Asynchronous-Stochastic-Gradient-Descent-for-}Multiverso,nni,onnxruntime{,-tvm},STL,Terminal,TypeScript,vcpkg,VFSForGit,vscode,vstest,wil},\
moby/{buildkit,moby},\
mono/{libgdiplus,linker,mono{,-tools,develop,torrent}},\
nanopb/nanopb,\
NervanaSystems/{coach,distiller,neon,ngraph},\
networkx/networkx,\
nico/demumble,\
nicolargo/glances,\
ninja-build/ninja,\
nlohmann/json,\
numpy/numpy{,doc},\
NVIDIA/{apex,cnmem,cuda-samples,cutlass,DALI{,_extra},Dataset_Synthesizer,DeepLearningExamples,DIGITS,flownet2-pytorch,libglvnd,Megatron-LM,NeMo,nccl,nccl-tests,nvidia-{container-runtime,docker,installer,modprobe,persistenced,settings,xconfig},NvPipe,nvvl,open-gpu-doc,OpenSeq2Seq,pix2pixHD,tacotron2,TensorRT,tensorrt-inference-server,vid2vid,waveglow},\
NVlabs/{cub,ffhq-dataset,pacnet,PWC-Net,SPADE,stylegan,xmp},\
oneapi-src/{one{API-{spec,tab},CCL,DAL,DNN,MKL,TBB},level-zero{,-tests}},\
onnx/{models,onnx{,-tensorrt,mltools},tutorials},\
open-mpi/ompi,\
open-source-parsers/jsoncpp,\
opencv/{ade,cvat,dldt,open_model_zoo,opencv{,_{3rdparty,contrib,extra}},openvino_training_extensions},\
OpenFOAM/{{OpenFOAM,ThirdParty}-{{2.{0,1,2,3,4},3.0,4,5}.x,6,7,dev},OpenFOAM-{Intel,Solidification},OpenQBMM},\
openssl/openssl,\
openwrt/{luci,openwrt,packages,targets,telephony,video},\
PeachPy/enum34,\
protocolbuffers/{protobuf,upb},\
pybind/pybind11,\
PythonCharmers/python-future,\
python-pillow/{Pillow,pillow-perf,Sane},\
pypa/{pip,pipenv,setuptools,virtualenv,warehouse,wheel},\
pytest-dev/{pluggy,py,pytest},\
python/typing,\
python-attrs/attrs,\
pytorch/{audio,botorch,captum,cppdocs,cpuinfo,elastic,examples,fairseq,FBGEMM,glow,ignite,pytorch,QNNPACK,serve,tensorpipe,text,translate,tutorials,vision,xla},\
RadeonOpenCompute/{hcc,ROCm-Device-Libs,ROCR-Runtime},\
RMerl/{am-toolchains,asuswrt-merlin.ng},\
ROCm-Developer-Tools/HIP,\
SchedMD/slurm,\
scipy/scipy{,-mathjax,-sphinx-theme},\
shadowsocks/{ShadowsocksX-NG,libQtShadowsocks,shadowsocks{,-go,-libev,-manager,-windows},v2ray-plugin},\
shibatch/sleef,\
sivel/{go-speedtest,speedtest-cli},\
Tencent/rapidjson,\
tensorflow/{agents,datasets,docs,io,models,tensorboard,tensorflow,transform},\
thrust/thrust,\
tmux/tmux,\
tmux-plugins/{tmux-{continuum,resurrect,sensible,test},tpm},\
torvalds/linux,\
tqdm/{py-make,tqdm},\
uploadcare/pillow-simd,\
USCiLab/cereal,\
v2ray/{dist,ext,geoip,homebrew-v2ray,v2ray-core,V2RayN},\
wjakob/clang-cindex-python3,\
xianyi/OpenBLAS,\
yaml/pyyaml,\
Yangqing/ios-cmake,\
zeromq/{cppzmq,libzmq,pyzmq},\
zeux/{meshoptimizer,pugixml},\
zfsonlinux/{pkg-{spl,zfs},spl,zfs{,-auto-snapshot,-buildbot,-images}},\
},\
https://gitlab.com/\ /\ {\
NVIDIA/cuda,\
},\
}

date
