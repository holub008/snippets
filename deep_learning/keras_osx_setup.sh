# not a keras requirement, but a lot of examples are in jupyter nbs
python3 -m pip install jupyter
# start up local service - verify the hello_world.ipynb
jupyter notebook

# needed for CPU based engines (tensorflow, theano)
brew install homebrew/science/openblas

# keras dependencies
python3 -m pip install numpy
python3 -m pip install scipy
python3 -m pip install matplotlib
python3 -m pip install pyyaml

pip3 install tensorflow

# for handling image / video data, which a lot of examples are built on
brew install opencv3 --with-contrib --with-python3
# permissions issues work around (likely unique to this system)
mkdir -p /Users/kholub/Library/Python/2.7/lib/python/site-packages
echo 'import site; site.addsitedir("/usr/local/lib/python2.7/site-packages")' >> /Users/kholub/Library/Python/2.7/lib/python/site-packages/homebrew.pth

# apparently for model serialization
python3 -m pip install h5py

# engines for keras to run on top of
python3 -m pip install tensorflow
python3 -m pip install theano

# install keras and run image classification example to verify functionality
python3 -m pip install keras
git clone https://github.com/fchollet/keras
python examples/mnist_cnn.py 

# missed a lib apparently
python3 -m pip install keras.datasets
