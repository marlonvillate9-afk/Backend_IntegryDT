package com.integrydt.backend.config;

import com.integrydt.backend.agent.*;import org.springframework.context.annotation.Configuration;import org.springframework.web.socket.config.annotation.*;
@Configuration @EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {private final AgentWebSocketHandler handler;private final AgentHandshakeInterceptor interceptor;public WebSocketConfig(AgentWebSocketHandler h,AgentHandshakeInterceptor i){handler=h;interceptor=i;}@Override public void registerWebSocketHandlers(WebSocketHandlerRegistry r){r.addHandler(handler,"/api/v1/agent/connect").addInterceptors(interceptor).setAllowedOriginPatterns("*");}}
