# ================================================================
# Account Configuration
# ================================================================

[ -e $STAGE/auth ] && ( set -xe
    cd
    mkdir -p .ssh
    cd .ssh
    rm -rvf id_{ecdsa,rsa}{,.pub}
    parallel -j0 --line-buffer --bar 'bash -c '"'"'
        set -e
        export ALGO="$(sed '"'"'s/,.*//'"'"' <<< '"'"'{}'"'"')"
        export BITS="$(sed '"'"'s/.*,//'"'"' <<< '"'"'{}'"'"')"
        ssh-keygen -qN "" -f "id_$ALGO" -t "$ALGO" -b "$BITS"
    '"'" ::: 'ecdsa,521' 'rsa,8192'
    cd $SCRATCH

    # ------------------------------------------------------------

    cd /etc/openldap
    for i in 'BASE' 'URI' 'TLS_CACERT' 'TLS_REQCERT'; do :
        if [ "$(grep "^[[:space:]#]*$i[[:space:]]" ldap.conf | wc -l)" -ne 1 ]; then
            sed "s/^[[:space:]#]*$i[[:space:]].*//" ldap.conf > .ldap.conf
            sudo mv -f .ldap.conf ldap.conf
            sudo echo '#'$i' ' >> ldap.conf
        fi
    done
    cat ldap.conf                                                                                               \
    | sed 's/^[[:space:]#]*\(BASE[[:space:]][[:space:]]*\).*/\1dc=codingcafe,dc=org/'                           \
    | sed 's/^[[:space:]#]*\(URI[[:space:]][[:space:]]*\).*/\1ldap:\/\/ldap.codingcafe.org/'                    \
    | sed 's/^[[:space:]#]*\(TLS_CACERT[[:space:]][[:space:]]*\).*/\1\/etc\/pki\/tls\/certs\/ca-bundle.crt/'    \
    | sed 's/^[[:space:]#]*\(TLS_REQCERT[[:space:]][[:space:]]*\).*/\1demand/'                                  \
    > .ldap.conf
    sudo mv -f .ldap.conf ldap.conf
    cd $SCRATCH

    # ------------------------------------------------------------

    # May fail at the first time in unprivileged docker due to domainname change.
    for i in $($IS_CONTAINER && echo true) false; do :
        sudo authconfig                                                                     \
            --enable{sssd{,auth},ldap{,auth,tls},locauthorize,cachecreds,mkhomedir}         \
            --disable{cache,md5,nis,rfc2307bis}                                             \
            --ldapserver=ldap://ldap.codingcafe.org                                         \
            --ldapbasedn=dc=codingcafe,dc=org                                               \
            --passalgo=sha512                                                               \
            --smbsecurity=user                                                              \
            --update                                                                        \
        || $i
    done

    sudo systemctl daemon-reload || $IS_CONTAINER
    for i in sssd; do :
        sudo systemctl enable $i
        sudo systemctl start $i || $IS_CONTAINER
    done

    # ------------------------------------------------------------

    git config --global user.name       'Tongliang Liao'
    git config --global user.email      'xkszltl@gmail.com'
    git config --global push.default    'matching'
    git config --global core.editor     'vim'
)
sudo rm -vf $STAGE/auth
sync || true
