#!/bin/bash

# user settings
repos_country=${repos_country:-jp} # set auto select download top domain
dl_domain=${dl_domain:-}        # use this domain instance of auto select by repos_country setting (e.g. ftp.tsukuba.wide.ad.jp

# work dir settings
workdir='/tmp'

# bootstrap settings
namebase='archlinux-bootstrap'
architecture='x86_64'
root_dir_name="root.${architecture}"
root_dir=${workdir}/${root_dir_name}

# image settings
chpacman=${chpacman:-true}
output_dir=$(pwd)
archive_path=${output_dir}/${tar_name:-archlinux.tar.xz}

# const
mirrorlist_url='https://www.archlinux.org/download/'
search_start_str='HTTP Direct Downloads'

# func
parse_url_cmd(){
    cat - | sed -e 's/.*href="\|".*//g'
}


# get donwload domain
dl_target=''
if [ "${dl_domain}" ]
then
    dl_target=$(curl -L "${mirrorlist_url}" | grep "${dl_domain}" | head -n1 | parse_url_cmd)
else
    mirrors=$(curl -L ${mirrorlist_url})
    start_line=$(echo "${mirrors}" | grep -nm1 "${search_start_str}" | cut -d: -f1)
    from_bottom=$(( $(echo "${mirrors}" | wc -l) - ${start_line} ))
    list=$(echo "${mirrors}" | tail -n ${from_bottom})
    dl_target=$(echo "${list}" | grep 'href=' | grep -m1 ".${repos_country}/" | parse_url_cmd)
fi

[ "${dl_target}" ] || {
    echo "Not found dl target: country ${repos_domain}, domain ${dl_domain}"
    exit 1
}

# get download link
list=$(curl -L "${dl_target}" | grep "${namebase}" | grep "${architecture}")
dl_file=$(echo "${list}" | grep -m1 -v 'sig' | parse_url_cmd)
sig_file=$(echo "${list}" | grep -m1 'sig' | parse_url_cmd)
if [[ ${dl_file} =~ ^http|ftp ]]
then
    dl_url=${dl_file}
    sig_url=${sig_file}
else
    dl_url=${dl_target%/}/${dl_file##/}
    sig_url=${dl_target%/}/${sig_file##/}
fi
dl_file=${dl_file##/}
sig_file=${sig_file##/}

# download
cd $workdir
curl -L ${sig_url} -O
curl -L ${dl_url} -O

# check tar
res=$(gpg --verify "${sig_file}" > /dev/null 2>&1; echo $?)
if [ ${res} -eq 2 ]
then
    # import and recheck
    key_id=$(LANG=C gpg --verify "${sig_file}" 2>&1 | sed -ne 's/.*RSA key ID //p')
    gpg --recv-keys ${key_id}
    res=$(gpg --verify "${sig_file}" > /dev/null 2>&1; echo $?)
fi
[ ${res} -ne 0 ] && {
    echo "Fail to check archive at ${sig_file}"
    exit
}

# extract
tar -zxf ${dl_file}
cd ${root_dir}

# pacman setting
${chpacman} && sed -i -e "/^#Server.*\.${repos_country}/s/^#//" etc/pacman.d/mirrorlist

# create archive
tar --no-same-owner -Jcf ${archive_path} .

exit

cd ${output_dir}
chmod 777 -R ${root_dir}
rm -rf ${archive_dir} ${dl_file} ${sig_file}
