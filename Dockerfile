FROM registry.fedoraproject.org/fedora-minimal:40@sha256:ccad6eb0e2218ca4d7930b7bf9c6dc08a6feaeda88c283a2edaef3cad93da399

RUN microdnf -y install \
        --setopt install_weak_deps=false \
        --setopt tsflags=nodocs \
        ShellCheck-0.9.0-6.fc40 \
        csdiff-3.3.0-1.fc40 \
        git-2.45.1-1.fc40 \
        python-unversioned-command-3.12.3-2.fc40 \
    && microdnf clean all

COPY src/ /opt/checkton/

CMD ["/opt/checkton/action.sh"]
