#!/bin/zsh

export SMPL_PATH="$(dirname $(readlink -f $0))"
export SMPL_REAL_ROOT="$SMPL_PATH/.root"
export SMPL_SRC="$SMPL_PATH/.src"
export SMPL_ROOT="/tmp/.smpl.$(uuidgen -t)-$(uuidgen -r)"

continue_stage=n
if [ -f "$SMPL_PATH/.continue_stage" ]
  then continue_stage=$(cat "$SMPL_PATH/.continue_stage")
fi

if [ -f "$SMPL_PATH/.continue_root" ]
  then SMPL_ROOT=$(cat "$SMPL_PATH/.continue_root")
fi

case $continue_stage in
  n)
    rm -f "$SMPL_PATH/.continue_stage"
    rm -rf "$SMPL_ROOT" "$SMPL_SRC" "$SMPL_REAL_ROOT"
    mkdir -p "$SMPL_REAL_ROOT" "$SMPL_SRC"
    ln -s "$SMPL_REAL_ROOT" "$SMPL_ROOT"
    echo "$SMPL_ROOT" > "$SMPL_PATH/.continue_root"
    ;&
  luajit)
    echo "luajit" > "$SMPL_PATH/.continue_stage"
    cd $SMPL_SRC
    git clone http://luajit.org/git/luajit-2.0.git luajit || exit
    cd luajit
    git checkout v2.1
    git pull
    make amalg PREFIX=$SMPL_ROOT CPATH=$SMPL_ROOT/include LIBRARY_PATH=$SMPL_ROOT/lib && \
    make install PREFIX=$SMPL_ROOT || exit
    ln -sf luajit-2.1.0-alpha $SMPL_ROOT/bin/luajit
    ;&
  luarocks)
    echo "luarocks" > "$SMPL_PATH/.continue_stage"
    cd $SMPL_SRC
    git clone git://github.com/keplerproject/luarocks.git || exit
    cd luarocks
    ./configure --prefix=$SMPL_ROOT \
                --lua-version=5.1 \
                --lua-suffix=jit \
                --with-lua=$SMPL_ROOT \
                --with-lua-include=$SMPL_ROOT/include/luajit-2.1 \
                --with-lua-lib=$SMPL_ROOT/lib/lua/5.1 \
                --force-config && \
    make build && make install || exit
    ;&
  moonscript)
    echo "moonscript" > "$SMPL_PATH/.continue_stage"
    $SMPL_ROOT/bin/luarocks install moonscript
    ;&
  luafilesystem)
    echo "luafilesystem" > "$SMPL_PATH/.continue_stage"
    $SMPL_ROOT/bin/luarocks install luafilesystem
    ;&
  lgi)
    echo "lgi" > "$SMPL_PATH/.continue_stage"
    $SMPL_ROOT/bin/luarocks install lgi
    ;&
  wrappers)
    echo "wrappers" > "$SMPL_PATH/.continue_stage"
    # wrappers
    cat > $SMPL_PATH/.run <<END
#!/bin/zsh
export SMPL_PATH="\$(dirname "\$(readlink -f "\$0")")"
export SMPL_REAL_ROOT="\$SMPL_PATH/.root"
export SMPL_ROOT="$SMPL_ROOT"

[ -e "\$SMPL_ROOT" ] || ln -s "\$SMPL_PATH/.root" \$SMPL_ROOT

export PATH="\$SMPL_ROOT/bin:\$PATH"
export LUA_PATH="./custom_?.lua;\$SMPL_PATH/custom_?.lua;./?.lua;./?/init.lua;\$SMPL_PATH/src/?/init.lua;\$SMPL_PATH/src/?.lua;\$SMPL_PATH/?.lua;\$LUA_PATH;\$SMPL_ROOT/lualib/?.lua;\$SMPL_ROOT/share/luajit-2.1.0-alpha/?.lua;\$SMPL_ROOT/share/lua/5.1/?.lua;\$SMPL_ROOT/share/lua/5.1/?/init.lua"
export LUA_CPATH="./custom_?.so;\$SMPL_PATH/custom_?.so;./?.so;./?/init.so;\$SMPL_PATH/src/?/init.so;\$SMPL_PATH/src/?.so;\$SMPL_PATH/?.so;\$LUA_CPATH;\$SMPL_ROOT/lualib/?.so;\$SMPL_ROOT/share/luajit-2.1.0-alpha/?.so;\$SMPL_ROOT/share/lua/5.1/?.so;\$SMPL_ROOT/share/lua/5.1/?/init.so"
export MOON_PATH="./custom_?.moon;\$SMPL_PATH/custom_?.moon;./?.moon;./?/init.moon;\$SMPL_PATH/src/?/init.moon;\$SMPL_PATH/src/?.moon;\$SMPL_PATH/?.moon;\$MOON_PATH;\$SMPL_ROOT/lualib/?.moon;\$SMPL_ROOT/share/luajit-2.1.0-alpha/?.moon;\$SMPL_ROOT/share/lua/5.1/?.moon;\$SMPL_ROOT/share/lua/5.1/?/init.moon"
export LD_LIBRARY_PATH="\$SMPL_ROOT/lib:\$LD_LIBRARY_PATH"

fn=\$(basename \$0)
if [ "\$fn" = ".run" ]
  then exec "\$@"
else
  exec \$fn "\$@"
fi
END
    chmod a+rx $SMPL_PATH/.run
    ln -sf .run $SMPL_PATH/moon
    ;&
esac

# cleanup
rm -rf "$SMPL_SRC"
rm -f "$SMPL_ROOT" "$SMPL_PATH/.continue_stage" "$SMPL_PATH/.continue_root"
