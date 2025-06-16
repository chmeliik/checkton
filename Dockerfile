FROM registry.fedoraproject.org/fedora-minimal:41@sha256:49a1571bf9533c02b5aafde97efbdc6d1746df747c5c570f1bae0395adf48e0e

# This image is also used to run tests, ncurses is needed for nicer output
ARG INSTALL_NCURSES=false

RUN microdnf -y install \
        --setopt install_weak_deps=false \
        --setopt tsflags=nodocs \
        csdiff \
        git-core \
        jq \
        python-unversioned-command \
        sarif-fmt \
        ShellCheck \
    && if [ "$INSTALL_NCURSES" = true ]; then microdnf -y install ncurses; fi \
    && microdnf clean all

COPY src/ /opt/checkton/

CMD ["/opt/checkton/action.sh"]
