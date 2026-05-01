#!/bin/bash

set -ex

echo
echo "==== ROCm Packages Installed ===="
dpkg -l | grep rocm || echo "No ROCm packages found."

echo
echo "==== Install dependencies and aiter ===="
git config --global --add safe.directory /workspace
pip config set global.retries 15
pip config set global.timeout 120
pip install --upgrade pandas pyzmq einops numpy==1.26.2 || {
    echo "WARNING: batch pip install failed, retrying packages individually..."
    pip install --upgrade pandas || true
    pip install --upgrade pyzmq || echo "WARNING: pyzmq unavailable (only needed by aiter.dist.shm_broadcast)"
    pip install --upgrade einops
    pip install --upgrade "numpy==1.26.2"
}
pip install -r .github/requirements/triton-test.txt
pip uninstall -y aiter || true
pip install --no-build-isolation -e .

# BUILD_TRITON=1 (default): build triton from source, overriding the pinned wheel.
BUILD_TRITON=${BUILD_TRITON:-1}

if [[ "$BUILD_TRITON" == "1" ]]; then
    echo
    echo "==== Install triton ===="
    pip uninstall -y triton || true

    TRITON_WHEEL_DIR=${TRITON_WHEEL_DIR:-}
    if [[ -n "$TRITON_WHEEL_DIR" ]] && ls "$TRITON_WHEEL_DIR"/*.whl 1>/dev/null 2>&1; then
        echo "Installing triton from pre-built wheel in $TRITON_WHEEL_DIR"
        pip install "$TRITON_WHEEL_DIR"/*.whl
    else
        echo "Building triton from source..."
        # Pin triton to a known-good commit to avoid CI breakage from
        # upstream changes (e.g. AMD codegen regressions in triton-lang/triton).
        TRITON_COMMIT=${TRITON_COMMIT:-756afc06}
        git clone https://github.com/triton-lang/triton || true
        cd triton
        git checkout "$TRITON_COMMIT"
        pip install -r python/requirements.txt
        MAX_JOBS=64 pip --retries=10 --default-timeout=60 install .
        cd ..
    fi
fi

echo
echo "==== Show installed packages ===="
pip list
