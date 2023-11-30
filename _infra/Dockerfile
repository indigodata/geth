ARG GO_IMAGE
FROM $GO_IMAGE

ARG GETH_REPO
ARG GETH_BRANCH

WORKDIR /indigo
RUN git clone $GETH_REPO /indigo/geth

WORKDIR /indigo/geth
RUN git checkout $GETH_BRANCH
RUN go install ./cmd/geth

WORKDIR /indigo