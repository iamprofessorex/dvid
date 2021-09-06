#!/usr/bin/env bash

export INTERFACE_DEVICE_NAME="ens33"

OS=$(uname -s)
ARCH=$(uname -m)
_whoami=$(whoami)

apt-get update
apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release net-tools

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo \
"pi ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/90-pi

apt-get update
# apt-get install -y docker-ce docker-ce-cli containerd.io


apt-cache madison docker-ce

export VERSION_STRING="5:20.10.8~3-0~ubuntu-focal"
export DOCKER_VERSION="5:20.10.8~3-0~ubuntu-focal"

apt-get install -y docker-ce="${VERSION_STRING}" docker-ce-cli="${VERSION_STRING}" containerd.io

# https://github.com/docker/compose/releases/tag/1.29.2


export DOCKER_COMPOSE_VERSION="1.29.2"
# sudo apt-get --allow-downgrades -y -o Dpkg::Options::="--force-confnew" install docker-ce=$(apt-cache madison docker-ce | grep $DOCKER_VERSION | head -1 | awk '{print $3}')
sudo rm -f /usr/local/bin/docker-compose
curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > docker-compose
chmod +x docker-compose
sudo mv docker-compose /usr/local/bin
echo ""
docker-compose --version
echo ""
# run docker commands as pi user (sudo not required)
usermod -aG docker pi
# install kubeadm
apt-get install -y apt-transport-https curl




# ip of this box
export IP_ADDR=`ifconfig "${INTERFACE_DEVICE_NAME}" | grep -i Mask | awk '{print $2}'| cut -f2 -d:`

echo "IP_ADDR = ${IP_ADDR}"
sudo apt-get -y install python3-minimal python3-apt
sudo apt-get install -y \
          bash-completion \
          curl \
          git \
          vim
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python3-six python3-pip
modprobe ip_vs_wrr
modprobe ip_vs_rr
modprobe ip_vs_sh
modprobe ip_vs
modprobe nf_conntrack_ipv4
modprobe bridge
modprobe br_netfilter
cat <<EOF >/etc/modules-load.d/k8s_ip_vs.conf
ip_vs_wrr
ip_vs_rr
ip_vs_sh
ip_vs
nf_conntrack_ipv4
EOF
cat <<EOF >/etc/modules-load.d/k8s_bridge.conf
bridge
EOF
cat <<EOF >/etc/modules-load.d/k8s_br_netfilter.conf
br_netfilter
EOF


# other good things to have

echo "* soft     nproc          500000" > /etc/security/limits.d/perf.conf
echo "* hard     nproc          500000" >> /etc/security/limits.d/perf.conf
echo "* soft     nofile         500000" >> /etc/security/limits.d/perf.conf
echo "* hard     nofile         500000"  >> /etc/security/limits.d/perf.conf
echo "root soft     nproc          500000" >> /etc/security/limits.d/perf.conf
echo "root hard     nproc          500000" >> /etc/security/limits.d/perf.conf
echo "root soft     nofile         500000" >> /etc/security/limits.d/perf.conf
echo "root hard     nofile         500000" >> /etc/security/limits.d/perf.conf
sed -i '/pam_limits.so/d' /etc/pam.d/sshd
echo "session    required   pam_limits.so" >> /etc/pam.d/sshd
sed -i '/pam_limits.so/d' /etc/pam.d/su
echo "session    required   pam_limits.so" >> /etc/pam.d/su
sed -i '/session required pam_limits.so/d' /etc/pam.d/common-session
echo "session required pam_limits.so" >> /etc/pam.d/common-session
sed -i '/session required pam_limits.so/d' /etc/pam.d/common-session-noninteractive
echo "session required pam_limits.so" >> /etc/pam.d/common-session-noninteractive
# NOTE: https://medium.com/@muhammadtriwibowo/set-permanently-ulimit-n-open-files-in-ubuntu-4d61064429a
# TODO: Put into playbook
echo "2097152" | sudo tee /proc/sys/fs/file-max

apt-get install -y conntrack ipset


sysctl -w vm.min_free_kbytes=1024000
sync; sysctl -w vm.drop_caches=3; sync
echo 1 >/sys/kernel/mm/ksm/run
echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs


# SOURCE: https://blog.openai.com/scaling-kubernetes-to-2500-nodes/ ( VERY GOOD )
echo "vm.min_free_kbytes=1024000" | tee -a /etc/sysctl.d/openai_perf.conf
echo "net.ipv4.neigh.default.gc_thresh1 = 80000" | tee -a /etc/sysctl.d/openai_perf.conf
echo "net.ipv4.neigh.default.gc_thresh2 = 90000" | tee -a /etc/sysctl.d/openai_perf.conf
echo "net.ipv4.neigh.default.gc_thresh3 = 100000" | tee -a /etc/sysctl.d/openai_perf.conf
# echo "sys.kernel.mm.ksm.run = 1" | tee -a /etc/sysctl.d/openai_perf.conf
# echo "sys.kernel.mm.ksm.sleep_millisecs = 1000" | tee -a /etc/sysctl.d/openai_perf.conf
echo "fs.file-max = 2097152" | tee -a /etc/sysctl.d/openai_perf.conf
sysctl -p
mkdir -p ~pi/dev
ls -lta ~pi/dev
git clone https://github.com/bossjones/debug-tools /usr/local/src/debug-tools || true
sudo chown -R ${_whoami}:${_whoami} /usr/local/bin
sudo chown -R ${_whoami}:${_whoami} /usr/local/src/debug-tools
/usr/local/src/debug-tools/update-bossjones-debug-tools
chown pi:pi -Rv ~pi
apt-get install software-properties-common -y
apt-add-repository ppa:ansible/ansible -y
apt-get update
apt-get install ansible -y

apt-get -y install bison build-essential cmake flex git libedit-dev \
libllvm6.0 llvm-6.0-dev libclang-6.0-dev python3 zlib1g-dev libelf-dev
apt-get -y install luajit luajit-5.1-dev

cd /usr/local/bin
wget -O grv https://github.com/rgburke/grv/releases/download/v0.3.1/grv_v0.3.1_linux64
chmod +x ./grv
cd -
### add packages (both necessary and convenient)
echo "Adding packages..." && \
apt-get install -y gcc make ncurses-dev libssl-dev bc && \
echo "Adding packages for perf..." && \
apt-get install -y flex bison libelf-dev libdw-dev libaudit-dev && \
echo "Adding packages for perf TUI..." && \
apt-get install -y libnewt-dev libslang2-dev && \
echo "Adding packages for convenience..." && \
apt-get install -y sharutils sysstat bc
# tigervnc
# https://www.cyberciti.biz/faq/install-and-configure-tigervnc-server-on-ubuntu-18-04/
apt-get install tigervnc-standalone-server tigervnc-xorg-extension tigervnc-viewer -y && \
apt-get install -y ubuntu-gnome-desktop
# systemctl enable gdm
# systemctl start gdm
fallocate -l 4G /swapfile && \
chmod 600 /swapfile && \
mkswap /swapfile && \
swapon /swapfile && \
echo "/swapfile swap swap defaults 0 0" | tee -a /etc/fstab && \
swapon --show && \
free -h


### asdf


# connecting to bastion k8s host -> ssh -oForwardAgent=yes -i ~/.ssh/id_rsa_balabit core@18.212.9.123
# scp -oForwardAgent=yes -i ~/.ssh/id_rsa_balabit core@18.212.9.123:journal.log .


git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.8.0 || true

echo "[asdf] enable"
. $HOME/.asdf/asdf.sh

# asdf plugin-add 1password https://github.com/samtgarson/asdf-1password.git # 1.6.0
# asdf plugin add goss https://github.com/raimon49/asdf-goss.git # 0.3.13
asdf plugin-add hadolint https://github.com/looztra/asdf-hadolint # 1.18.0
asdf plugin add fd # 8.1.1
asdf plugin-add tmux https://github.com/aphecetche/asdf-tmux.git # 2.9a
asdf plugin-add helm https://github.com/Antiarchitect/asdf-helm.git # 3.3.1
asdf plugin-add jsonnet https://github.com/Banno/asdf-jsonnet.git # 0.16.0
asdf plugin-add k9s https://github.com/looztra/asdf-k9s # 0.21.7
asdf plugin-add kubectl https://github.com/Banno/asdf-kubectl.git # 1.18.6
asdf plugin add kubectx # 0.9.1
asdf plugin-add kubeval https://github.com/stefansedich/asdf-kubeval # 0.15.0
asdf plugin-add neovim # 0.4.4
asdf plugin-add packer https://github.com/Banno/asdf-hashicorp.git # 1.6.2
asdf plugin-add terraform https://github.com/Banno/asdf-hashicorp.git # 0.13.2
asdf plugin-add vault https://github.com/Banno/asdf-hashicorp.git # 1.5.3
asdf plugin-add poetry https://github.com/crflynn/asdf-poetry.git # 1.0.10
asdf plugin-add yq https://github.com/sudermanjr/asdf-yq.git # 3.2.3
asdf plugin-add kubetail https://github.com/janpieper/asdf-kubetail.git

# asdf install goss 0.3.13
# asdf global goss 0.3.13

# asdf install fd 8.1.1
# asdf global fd 8.1.1

# asdf install k9s 0.24.15
# asdf global k9s 0.24.15

asdf install kubetail 1.6.13
asdf global kubetail 1.6.13

apt-get update; apt-get install curl wget vim zsh -y

# wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh
# echo -e "Y\n" | zsh ./install.sh

# wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh

mkdir -p  ~/kubetail/completion/
curl -L 'https://raw.githubusercontent.com/johanhaleby/kubetail/master/completion/kubetail.bash' > ~/kubetail/completion/kubetail.bash

source ~/kubetail/completion/kubetail.bash

# zsh

# SOURCE: https://github.com/aylei/kubectl-debug
export PLUGIN_VERSION=0.1.1
# linux x86_64
curl -Lo kubectl-debug.tar.gz https://github.com/aylei/kubectl-debug/releases/download/v${PLUGIN_VERSION}/kubectl-debug_${PLUGIN_VERSION}_linux_amd64.tar.gz
tar -zxvf kubectl-debug.tar.gz kubectl-debug
mv kubectl-debug /usr/local/bin/



### pyenv setup


set -e

export DEBIAN_FRONTEND=noninteractive

if [[ "${EUID}" == "0" ]]; then
   echo "This script must NOT be run as root"
   exit 1
fi

sudo apt-get update && \
    sudo apt-get install -y locales ca-certificates && \
    sudo apt-get clean && \
    sudo localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

set +e

export LANG=en_US.UTF-8

export PYENV_ROOT="/.pyenv"
export PATH="/.pyenv/bin:/.pyenv/shims:$PATH"

export BASHRC_FILE=~pi/.bashrc

echo "3.9.0" > python-versions.txt

sudo rm -rfv /.pyenv || true && \
sudo rm -rfv ~/.pyenv || true
# sudo mkdir /.pyenv || true && \
# sudo chown 0777 /.pyenv || truevim


set -x


export PATH="~/.bin:~/.local/bin:$PATH"
export PYENV_ROOT="/.pyenv"
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
# Edit Config File
if ! grep -q 'export PATH="~/.bin:~/.local/bin:$PATH"' "${BASHRC_FILE}" ; then\
    echo 'export PATH="~/.bin:~/.local/bin:$PATH"' >> "${BASHRC_FILE}" ;\
    export PATH="~/.bin:~/.local/bin:$PATH" ;\
fi
if ! grep -q 'export PYENV_ROOT="/.pyenv"' "${BASHRC_FILE}" ; then\
    echo 'export PYENV_ROOT="/.pyenv"' >> "${BASHRC_FILE}" ;\
    export PYENV_ROOT="/.pyenv" ;\
fi
if ! grep -q 'export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"' "${BASHRC_FILE}" ; then\
    echo 'export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"' >> "${BASHRC_FILE}" ;\
    export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH" ;\
fi
if ! grep -q 'eval "$(pyenv init -)"' "${BASHRC_FILE}" ; then\
    echo 'eval "$(pyenv init -)"' >> "${BASHRC_FILE}" ;\
    eval "$(pyenv init -)" ;\
fi
if ! grep -q 'eval "$(pyenv virtualenv-init -)"' "${BASHRC_FILE}" ; then\
    echo 'eval "$(pyenv virtualenv-init -)"' >> "${BASHRC_FILE}" ;\
    eval "$(pyenv virtualenv-init -)" ;\
fi


cat ${BASHRC_FILE}

. ${BASHRC_FILE}

set +x

set -e
sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends git ca-certificates curl && \
    curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer > ./pyenv-installer && \
    chmod +x ./pyenv-installer && \
    sudo env PYENV_ROOT="/.pyenv" PATH="/.pyenv/bin:/.pyenv/shims:$PATH" $(pwd)/pyenv-installer && \
    sudo apt-get clean

# sudo chmod 0777 -R /.pyenv || true

sudo chown -Rv pi:pi ${PYENV_ROOT}

source ${BASHRC_FILE}

git clone https://github.com/pyenv/pyenv-virtualenvwrapper.git $(pyenv root)/plugins/pyenv-virtualenvwrapper || true

set -x;
sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends \
        make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
        libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev \
        libxml2-dev libxmlsec1-dev libffi-dev \
        ca-certificates && \
    sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev libffi-dev liblzma-dev python-openssl git && \
    sudo apt-get clean
set +e


exec "$SHELL"
set -x;
pyenv update && \
            xargs -P 4 -n 1 pyenv install < ./python-versions.txt && \
            pyenv global $(pyenv versions --bare) && \
            find $PYENV_ROOT/versions -type d '(' -name '__pycache__' -o -name 'test' -o -name 'tests' ')' -exec rm -rfv '{}' + && \
            find $PYENV_ROOT/versions -type f '(' -name '*.py[co]' -o -name '*.exe' ')' -exec rm -fv '{}' + && \
            mv -v -- ./python-versions.txt $PYENV_ROOT/version

exec "$SHELL"

export PYENV_VERSION=3.9.0
python -c "import sys;print(sys.executable)"


$PYENV_ROOT/versions/$PYENV_VERSION/bin/pip install -U pip setuptools && \
$PYENV_ROOT/versions/$PYENV_VERSION/bin/pip install -U virtualenv && \
$PYENV_ROOT/versions/$PYENV_VERSION/bin/pip install -U virtualenvwrapper


# install stuff for vim
# https://github.com/bossjones/python-vimrc

sudo apt-get install -y build-essential cmake python3-dev ctop
set +x;

cd ~/dev && \
git clone https://github.com/bossjones/bosslab-playbooks || true && \
cd bosslab-playbooks && \
pyenv virtualenv $PYENV_VERSION ansible3 || true  && \
pyenv activate ansible3 || true  && \
pyenv rehash && \
sed -i '/ansigenome/d' requirements.in && \
sed -i '/ansible-inventory-grapher/d' requirements.in && \
sed -i '/ansible-playbook-grapher/d' requirements.in && \
/.pyenv/versions/$PYENV_VERSION/envs/ansible3/bin/python -m pip install -U pip setuptools || true  && \
/.pyenv/versions/$PYENV_VERSION/envs/ansible3/bin/python -m pip install pip-tools pipdeptree --upgrade || true  && \
/.pyenv/versions/$PYENV_VERSION/envs/ansible3/bin/pip-compile --output-file requirements.txt requirements.in --upgrade && \
/.pyenv/versions/$PYENV_VERSION/envs/ansible3/bin/pip-compile --output-file requirements-dev.txt requirements-dev.in --upgrade && \
/.pyenv/versions/$PYENV_VERSION/envs/ansible3/bin/pip-compile --output-file requirements-test.txt requirements-test.in --upgrade && \
/.pyenv/versions/$PYENV_VERSION/envs/ansible3/bin/python -m pip install -r requirements.txt && \
/.pyenv/versions/$PYENV_VERSION/envs/ansible3/bin/python -m pip install -r requirements-dev.txt && \
/.pyenv/versions/$PYENV_VERSION/envs/ansible3/bin/python -m pip install -r requirements.txt && \
cd -

pyenv rehash

sudo apt-get install -y fzf jq rbenv silversearcher-ag tmux tree direnv

cd ~/dev && \
git clone https://github.com/bossjones/ansible-role-oh-my-zsh || true && \
git clone https://github.com/bossjones/linux-dotfiles ~/.dotfiles || true


# ansible run fails if we don't have this
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf || true && \
~/.fzf/install --all


sudo touch /usr/local/bin/install-config
sudo chown pi:pi /usr/local/bin/install-config
cat <<EOF >/usr/local/bin/install-config
export PYENV_VERSIONS_TO_INSTALL="3.9.0\n"
export PYENV_ROOT=/.pyenv
export PATH="${PYENV_ROOT}/bin:${PYENV_ROOT}/shims:$PATH"
export RBENV_ROOT=~/.rbenv
export RBENV_VERSION=2.6.6
export NODE_VERSION_TO_INSTALL=10.3.0
export PATH="$HOME/.fnm:${RBENV_ROOT}/shims:${RBENV_ROOT}/bin:$PATH"
EOF
cat /usr/local/bin/install-config

# fnm
export NODE_VERSION_TO_INSTALL=10.3.0
install-fnm.sh
export PATH=/home/pi/.fnm:$PATH
eval "`fnm env`"
exec "$SHELL"


# add it to root as well
if ! sudo grep -q 'export PATH=/home/pi/.fnm:$PATH' /root/.bashrc ; then\
    echo 'export PATH=/home/pi/.fnm:$PATH' | sudo tee -a /root/.bashrc ;\
    export PATH=/home/pi/.fnm:$PATH ;\
fi
if ! sudo grep -q 'eval "`fnm env`"' /root/.bashrc ; then\
    echo 'eval "`fnm env`"'  | sudo tee -a /root/.bashrc  ;\
    eval "`fnm env`" ;\
fi

sudo cat /root/.bashrc


exec "$SHELL"

echo "[kube-install] Installing Kubernetes" && \
sudo apt-get update && apt-get install -y apt-transport-https curl && \
sudo apt-get update && \
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add && \
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main" && \
sudo apt-get update  && \
sudo apt-get install -y kubeadm kubelet kubectl kubernetes-cni

# export K8S_STABLE=$(curl -L -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
# echo ${K8S_STABLE}
# # install kubectl convert plugin
# curl -LO https://dl.k8s.io/release/${K8S_STABLE}/bin/linux/amd64/kubectl-convert
# curl -LO "https://dl.k8s.io/${K8S_STABLE}/bin/linux/amd64/kubectl-convert.sha256"
# echo "$(<kubectl-convert.sha256) ./kubectl-convert" | sha256sum --check
# sudo install -o root -g root -m 0755 kubectl-convert /usr/local/bin/kubectl-convert
# kubectl convert --help

(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz" &&
  tar zxvf krew.tar.gz &&
  KREW=./krew-"${OS}_${ARCH}" &&
  "$KREW" install krew
)

# vim ~/.zsh.d/before/krew.zsh
if ! grep -q 'export PATH="${PATH}:${HOME}/.krew/bin"' ~/.zsh.d/before/krew.zsh ; then\
    echo 'export PATH="${PATH}:${HOME}/.krew/bin"'  | tee -a ~/.zsh.d/before/krew.zsh  ;\
    export PATH="${PATH}:${HOME}/.krew/bin" ;\
fi

# vim ~/.zsh.d/before/krew.zsh
if ! grep -q 'export PATH="${PATH}:${HOME}/.krew/bin"' "${BASHRC_FILE}"; then\
    echo 'export PATH="${PATH}:${HOME}/.krew/bin"'  | tee -a "${BASHRC_FILE}" ;\
    export PATH="${PATH}:${HOME}/.krew/bin" ;\
fi


exec "$SHELL"



kubectl krew install janitor
kubectl krew install mtail
kubectl krew install node-restart
kubectl krew index add kvaps kvaps/krew-index
kubectl krew install kvaps/node-shell
kubectl krew install np-viewer
kubectl krew install outdated
kubectl krew install exec-as
kubectl krew install prompt
kubectl krew install prune-unused
kubectl krew install rbac-view
kubectl krew install service-tree
kubectl krew install sniff
kubectl krew install socks5-proxy
kubectl krew install spy
kubectl krew install tmux-exec
kubectl krew install trace
kubectl krew install tree
kubectl krew install unused-volumes
kubectl krew install view-cert
kubectl krew install view-secret
kubectl krew install view-utilization
kubectl krew install who-can
kubectl krew install whoami
kubectl krew install blame
kubectl krew install mtail
kubectl krew install ca-cert
kubectl krew install view-secret
kubectl krew install capture
kubectl krew install cert-manager
kubectl krew install cilium
kubectl krew install cyclonus
kubectl krew install deprecations
curl https://krew.sh/df-pv | bash
kubectl krew install doctor
kubectl krew install exec-cronjob
kubectl krew install flame
kubectl krew install gadget
kubectl krew install get-all
kubectl krew install graph
kubectl krew install grep
kubectl krew install images
kubectl krew install access-matrix
kubectl krew install assert
kubectl krew install ingress-nginx




kubectl plugin list



if ! grep -q 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' ~/.zshrc ; then\
    echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"'  | tee -a ~/.zshrc  ;\
    export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH" ;\
fi
if ! grep -q 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' ~/.bashrc ; then\
    echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"'  | tee -a ~/.bashrc  ;\
    export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH" ;\
fi

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

kubectl krew

sudo apt-get install rustc ripgrep xclip urlview -y

cd ~/dev
git clone https://github.com/facebook/PathPicker.git
cd PathPicker/debian
./package.sh
sudo dpkg -i ../pathpicker_0.9.2_all.deb
cd -

sudo /sbin/sysctl -w net.ipv4.ip_forward="1"
sudo /sbin/sysctl -w net.ipv6.conf.all.forwarding="1"

cd ~/dev
git clone https://github.com/geerlingguy/ansible-role-postgresql.git || true
cat <<EOF >~/dev/ansible-role-postgresql/site.yml
---
- name: Converge
  hosts: all
  become: true

  vars:
    ansible_python_interpreter: /usr/bin/python3
    postgresql_python_library: python3-psycopg2
    postgresql_global_config_options:
        - option: listen_addresses
          value: '*'
    postgresql_hba_entries:
    - { type: local, database: all, user: postgres, auth_method: peer }
    - { type: local, database: all, user: all, auth_method: peer }
    - { type: host, database: all, user: all, address: '127.0.0.1/32', auth_method: md5 }
    - { type: host, database: all, user: all, address: '::1/128', auth_method: md5 }
    - { type: host, database: all, user: all, address: '192.168.1.0/16', auth_method: trust }

    postgresql_databases:
      - name: kubernetes
        # lc_collate: # defaults to 'en_US.UTF-8'
        # lc_ctype: # defaults to 'en_US.UTF-8'
        # encoding: # defaults to 'UTF-8'
        # template: # defaults to 'template0'
        login_host: "192.168.1.62" # defaults to 'localhost'
        login_password: "password" # defaults to not set
        # login_user: # defaults to '{{ postgresql_user }}'
        # login_unix_socket: # defaults to 1st of postgresql_unix_socket_directories
        port: 5432 # defaults to not set
        # owner: # defaults to postgresql_user
        # state: # defaults to 'present'
      - name: k3s
        # lc_collate: # defaults to 'en_US.UTF-8'
        # lc_ctype: # defaults to 'en_US.UTF-8'
        # encoding: # defaults to 'UTF-8'
        # template: # defaults to 'template0'
        login_host: "192.168.1.62" # defaults to 'localhost'
        login_password: "password" # defaults to not set
        # login_user: # defaults to '{{ postgresql_user }}'
        # login_unix_socket: # defaults to 1st of postgresql_unix_socket_directories
        port: 5432 # defaults to not set
        # owner: # defaults to postgresql_user
        # state: # defaults to 'present'
    postgresql_users:
      - name: postgres
        password: "password"
        login_password: "password"
      - name: pi
        password: "password"
        login_password: "password"
    postgres_users_no_log: false

  pre_tasks:
    # The Fedora 30+ container images have only C.UTF-8 installed
    - name: Set database locale if using Fedora 30+ or RedHat 8+
      set_fact:
        postgresql_databases:
          - name: kubernetes
            # lc_collate: # defaults to 'en_US.UTF-8'
            # lc_ctype: # defaults to 'en_US.UTF-8'
            # encoding: # defaults to 'UTF-8'
            # template: # defaults to 'template0'
            login_host: "192.168.1.62" # defaults to 'localhost'
            login_password: "password" # defaults to not set
            # login_user: # defaults to '{{ postgresql_user }}'
            # login_unix_socket: # defaults to 1st of postgresql_unix_socket_directories
            port: 5432 # defaults to not set
            # owner: # defaults to postgresql_user
            # state: # defaults to 'present'
          - name: k3s
            # lc_collate: # defaults to 'en_US.UTF-8'
            # lc_ctype: # defaults to 'en_US.UTF-8'
            # encoding: # defaults to 'UTF-8'
            # template: # defaults to 'template0'
            login_host: "192.168.1.62" # defaults to 'localhost'
            login_password: "password" # defaults to not set
            # login_user: # defaults to '{{ postgresql_user }}'
            # login_unix_socket: # defaults to 1st of postgresql_unix_socket_directories
            port: 5432 # defaults to not set
            # owner: # defaults to postgresql_user
            # state: # defaults to 'present'
      when:
        - ( ansible_distribution == 'Fedora' and ansible_distribution_major_version >= '30') or
          ( ansible_os_family == 'RedHat' and ansible_distribution_major_version == '8')

    - name: Update apt cache.
      apt: update_cache=true cache_valid_time=600
      changed_when: false
      when: ansible_os_family == 'Debian'

  roles:
    - role: ../

  post_tasks:
    - name: Verify postgres is running.
      command: "{{ postgresql_bin_path }}/pg_ctl -D {{ postgresql_data_dir }} status"
      changed_when: false
      become: true
      become_user: postgres
EOF

cd -

# /etc/systemd/system/k3s.service.d/30-certificates.conf
sudo mkdir -p /etc/systemd/system/k3s.service.d/
echo '[Service]' | sudo tee /etc/systemd/system/k3s.service.d/override.conf
echo "Environment=K3S_DATASTORE_ENDPOINT=postgres://pi:password@192.168.1.62:5432/k3s" | sudo tee /etc/systemd/system/k3s.service.d/override.conf
# echo "Environment=K3S_URL=https://192.168.1.62:6443" | sudo tee /etc/systemd/system/k3s.service.d/override.conf

# how to connect to posgres: pgcli postgres://pi:password@192.168.1.62:5432/k3s
# -tls-san 192.168.1.62

cd ~/dev
git clone https://github.com/k3s-io/k3s-ansible || true
cp -R k3s-ansible/inventory/sample k3s-ansible/inventory/my-cluster
cat <<EOF >~/dev/k3s-ansible/inventory/my-cluster/group_vars/all.yml
---
k3s_version: v1.21.4+k3s1
ansible_user: pi
systemd_dir: /etc/systemd/system
master_ip: "{{ hostvars[groups['master'][0]]['ansible_host'] | default(groups['master'][0]) }}"
extra_server_args: "-tls-san 192.168.1.62"
extra_agent_args: ""
EOF

cat <<EOF >~/dev/k3s-ansible/inventory/my-cluster/hosts.ini
192.168.1.62 ansible_ssh_host=192.168.1.62 ansible_ssh_private_key_file=~/.ssh/id_rsa ip=192.168.1.62 ansible_ssh_port=22 ansible_ssh_user='pi' ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -o ControlMaster=auto -o ControlPersist=60s -o ControlPath=~/.ansible/cp/ansible-ssh-%h-%p-%r' boss__kubernetes__kubeadm__server_type=master is_master=true

192.168.1.63 ansible_ssh_host=192.168.1.63 ansible_ssh_private_key_file=~/.ssh/id_rsa ip=192.168.1.63 ansible_ssh_port=22 ansible_ssh_user='pi' ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -o ControlMaster=auto -o ControlPersist=60s -o ControlPath=~/.ansible/cp/ansible-ssh-%h-%p-%r' boss__kubernetes__kubeadm__server_type=master is_master=true

192.168.1.64 ansible_ssh_host=192.168.1.64 ansible_ssh_private_key_file=~/.ssh/id_rsa ip=192.168.1.64 ansible_ssh_port=22 ansible_ssh_user='pi' ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -o ControlMaster=auto -o ControlPersist=60s -o ControlPath=~/.ansible/cp/ansible-ssh-%h-%p-%r' boss__kubernetes__kubeadm__server_type=master is_master=true

; k3lab-node-03.dev.home ansible_ssh_host=k3lab-node-03 ansible_ssh_private_key_file=~/.ssh/id_rsa ip=192.168.1.16 ansible_ssh_port=22 ansible_ssh_user='pi' ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -o ControlMaster=auto -o ControlPersist=60s -o ControlPath=~/.ansible/cp/ansible-ssh-%h-%p-%r' boss__kubernetes__kubeadm__server_type=master is_master=true

; k3lab-node-04.dev.home ansible_ssh_host=k3lab-node-04 ansible_ssh_private_key_file=~/.ssh/id_rsa ip=192.168.1.32 ansible_ssh_port=22 ansible_ssh_user='pi' ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -o ControlMaster=auto -o ControlPersist=60s -o ControlPath=~/.ansible/cp/ansible-ssh-%h-%p-%r' boss__kubernetes__kubeadm__server_type=master is_master=true

localhost ansible_connection=local

[local]
localhost ansible_connection=local

[lab1]
192.168.1.62

[lab2]
192.168.1.63

[lab3]
192.168.1.64

; [k3lab-node-03]
; k3lab-node-03.dev.home

; [k3lab-node-04]
; k3lab-node-04.dev.home


# CHILDREN
[master:children]
lab1

[masters:children]
lab1

[node:children]
lab2
lab3
; k3lab-node-03
; k3lab-node-04

[k3s_cluster:children]
master
node

[servers:children]
masters

[all:children]
servers

[rsyslogd_masters:children]
lab1

[rsyslogd_clients:children]
lab1


[nfs_masters:children]
lab1

[nfs_clients:children]
lab1


[influxdb:children]
lab1

[graphite-master1:children]
lab1

# groups of groups = children
[graphite-master-servers:children]
graphite-master1

[netdata_registry:children]
masters

[netdata_nodes:children]
lab1



EOF

# K3S_TOKEN=SECRET


sudo systemctl stop kubelet
sudo systemctl disable kubelet


# install-cgroup-tools.sh
install-code-shell-tmux.sh
install-compile-tools.sh
install-ctags.sh
# install-ctop.sh
install-fonts.sh
install-fx.sh
install-go.sh
install-goss.sh
install-jid.sh pi
install-kubebox.sh pi
# install-powerline-fonts.sh
install-rbenv.sh
install-tmux.sh
install-vim.sh
install-neovim-config.sh pi
install-cheat.sh pi
install-node.sh

cd ansible-role-oh-my-zsh
sudo ansible-playbook -vvvvv -i "localhost," -c local playbook_ubuntu_pure.yml --extra-vars="bossjones__oh__my__zsh__user=pi bossjones__oh__my__zsh__theme=pure"

mkdir -p ~/.tmuxinator || true
cat <<EOF >~/.tmuxinator/zsh.yml
# ~/.tmuxinator/zsh.yml
name: zsh
root: ~/

# Runs in each window and pane before window/pane specific commands. Useful for setting up interpreter versions.
# pre_window: exec zsh -l

windows:
  - neofetch:
      layout: 9fa4,223x75,0,0{118x75,0,0[118x52,0,0{59x52,0,0,8,58x52,60,0,13},118x22,0,53,12],104x75,119,0[104x16,119,0,1,104x15,119,17,9,104x22,119,33,2,104x19,119,56,3]}
      panes:
        - neofetch:
          - neofetch



# sh -c "$(curl -fsSL https://raw.githubusercontent.com/ets-labs/python-vimrc/master/setup.sh)"
EOF

sudo apt-get install libpcre2-dev -y
sudo apt-get install -y automake pkg-config libpcre3-dev zlib1g-dev liblzma-dev

echo 'network: {config: disabled}' | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
