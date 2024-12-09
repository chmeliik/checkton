FROM registry.fedoraproject.org/fedora-minimal:41@sha256:06a9691ef903f93d931273ee86067b29458b8ab73441f2da0fa0fa88b1615933

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
