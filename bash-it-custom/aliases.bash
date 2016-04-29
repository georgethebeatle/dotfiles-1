alias gfd='bosh create release --force && bosh -n upload release && bosh -n deploy'

alias clup='pushd ~/workspace/concourse-lite; vagrant destroy -f; vagrant up; popd'
function blup() {
  stemcell=$1
  pushd ~/workspace/bosh-lite
  git pull --rebase
  vagrant destroy -f
  vagrant up
  sudo ./bin/add-route
  bosh target 192.168.50.4 lite
  if [ ! -z $stemcell ] && [ -f $stemcell ]; then
    bosh upload stemcell $stemcell
  fi
  popd
}

alias resprout='pushd ~/workspace/sprout-wrap/cf-garden; git pull --rebase && soloist; popd'

alias z='fasd_cd -d'
alias z='fasd_cd -d -i'
