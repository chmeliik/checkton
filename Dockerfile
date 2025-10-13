FROM registry.fedoraproject.org/fedora-minimal:42@sha256:23ee5e060ecaea5e5c101d7451a28c8dd79039293fc72c96fd1ac6f8b93329ee

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
