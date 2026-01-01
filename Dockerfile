FROM registry.fedoraproject.org/fedora-minimal:42@sha256:aea5fea33dee52e56307401035b4440802d2f9649ac9b1718bdd0d5f1f8351b7

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
