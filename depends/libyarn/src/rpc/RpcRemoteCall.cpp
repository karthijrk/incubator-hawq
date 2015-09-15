/********************************************************************
 * Copyright (c) 2014, Pivotal Inc.
 * All rights reserved.
 *
 * Author: Zhanwei Wang
 ********************************************************************/
#include "Memory.h"
#include "YARNProtobufRpcEngine.pb.h"
#include "RpcCall.h"
#include "RpcContentWrapper.h"
#include "YARNRpcHeader.pb.h"
#include "RpcRemoteCall.h"
#include "WriteBuffer.h"

#include <google/protobuf/io/coded_stream.h>

#define PING_CALL_ID -4

using namespace google::protobuf::io;

namespace Yarn {
namespace Internal {

void RpcRemoteCall::serialize(const RpcProtocolInfo & protocol,
                              WriteBuffer & buffer) {
    hadoop::common::RpcRequestHeaderProto rpcHeader;
    rpcHeader.set_callid(identity);
    rpcHeader.set_clientid(clientId);
    rpcHeader.set_retrycount(-1);
    rpcHeader.set_rpckind(hadoop::common::RPC_PROTOCOL_BUFFER);
    rpcHeader.set_rpcop(hadoop::common::RpcRequestHeaderProto_OperationProto_RPC_FINAL_PACKET);
    hadoop::common::RequestHeaderProto requestHeader;
    requestHeader.set_methodname(call.getName());
    requestHeader.set_declaringclassprotocolname(protocol.getProtocol());
    requestHeader.set_clientprotocolversion(protocol.getVersion());
    RpcContentWrapper wrapper(&requestHeader, call.getRequest());
    int rpcHeaderLen = rpcHeader.ByteSize();
    int size = CodedOutputStream::VarintSize32(rpcHeaderLen) + rpcHeaderLen + wrapper.getLength();
    buffer.writeBigEndian(size);
    buffer.writeVarint32(rpcHeaderLen);
    rpcHeader.SerializeToArray(buffer.alloc(rpcHeaderLen), rpcHeaderLen);
    wrapper.writeTo(buffer);
}

std::vector<char> RpcRemoteCall::GetPingRequest(const std::string & clientid) {
    WriteBuffer buffer;
    std::vector<char> retval;
    hadoop::common::RpcRequestHeaderProto pingHeader;
    pingHeader.set_callid(PING_CALL_ID);
    pingHeader.set_clientid(clientid);
    pingHeader.set_retrycount(INVALID_RETRY_COUNT);
    pingHeader.set_rpckind(hadoop::common::RpcKindProto::RPC_PROTOCOL_BUFFER);
    pingHeader.set_rpcop(hadoop::common::RpcRequestHeaderProto_OperationProto_RPC_FINAL_PACKET);
    int rpcHeaderLen = pingHeader.ByteSize();
    int size = CodedOutputStream::VarintSize32(rpcHeaderLen) + rpcHeaderLen;
    buffer.writeBigEndian(size);
    buffer.writeVarint32(rpcHeaderLen);
    pingHeader.SerializeWithCachedSizesToArray(reinterpret_cast<unsigned char *>(buffer.alloc(pingHeader.ByteSize())));
    retval.resize(buffer.getDataSize(0));
    memcpy(&retval[0], buffer.getBuffer(0), retval.size());
    return retval;
}

}
}

