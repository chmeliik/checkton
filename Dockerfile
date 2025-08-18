FROM registry.fedoraproject.org/fedora-minimal:42@sha256:4094ef43fddef24401e10c21e09803adeb57f4c10a050296316d4f23890790d2

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
