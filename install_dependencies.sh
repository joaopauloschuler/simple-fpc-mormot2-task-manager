sudo apt update
# install fpc only if it not already installed
if ! command -v fpc &> /dev/null
then
    echo "fpc could not be found, installing..."
    sudo apt install -y fpc
else
    echo "fpc is already installed"
fi
# install git, wget, tar if not already installed
if ! command -v git &> /dev/null
then
    echo "git could not be found, installing..."
    sudo apt install -y git
else
    echo "git is already installed"
fi
if ! command -v wget &> /dev/null
then
    echo "wget could not be found, installing..."
    sudo apt install -y wget
else
    echo "wget is already installed"
fi
if ! command -v tar &> /dev/null
then
    echo "tar could not be found, installing..."
    sudo apt install -y tar
else
    echo "tar is already installed" 
fi
cd ..
pwd
# clone mORMot2 repository if not already cloned
if [ ! -d "mORMot2" ]; then
    git clone https://github.com/synopse/mORMot2.git
fi
cd mORMot2/static
# download mormot2static.tgz if not already downloaded
if [ ! -f "mormot2static.tgz" ]; then
    wget https://synopse.info/files/mormot2static.tgz
    tar -xvf mormot2static.tgz
fi
pwd