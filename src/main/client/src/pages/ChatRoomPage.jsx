import React, { useState, useEffect, useRef } from "react";
import { useParams } from "react-router-dom";
import axios from "axios";
import SockJS from "sockjs-client";
import { Client } from "@stomp/stompjs";

const ChatRoomPage = () => {
    const { chatRoomId } = useParams();
    const [messages, setMessages] = useState([]);
    const [inputMessage, setInputMessage] = useState("");
    const [isConnected, setIsConnected] = useState(false);
    const [currentUserNickname, setCurrentUserNickname] = useState(null);
    const stompClientRef = useRef(null);
    const messageEndRef = useRef(null);
    const isComposing = useRef(false);

    useEffect(() => {
        const token = localStorage.getItem("token");
        if (!token) return;

        // ✅ 현재 로그인한 사용자의 닉네임 가져오기
        const fetchUserNickname = async () => {
            try {
                const response = await axios.get("http://localhost:8080/profile/me", {
                    headers: { Authorization: `Bearer ${token}` },
                });
                setCurrentUserNickname(response.data.nickname);
            } catch (error) {
                console.error("사용자 닉네임 가져오기 실패:", error);
            }
        };
        fetchUserNickname();
    }, []);

    useEffect(() => {
        if (!chatRoomId) return;
        const token = localStorage.getItem("token");
        if (!token) return;

        const fetchChatHistory = async () => {
            try {
                const response = await axios.get(`http://localhost:8080/chat/${chatRoomId}`, {
                    headers: { Authorization: `Bearer ${token}` },
                });
                setMessages(response.data);
            } catch (error) {
                console.error("채팅 기록 불러오기 실패:", error);
            }
        };
        fetchChatHistory();
    }, [chatRoomId]);

    useEffect(() => {
        if (!chatRoomId) return;
        const token = localStorage.getItem("token");
        if (!token) return;

        const socket = new SockJS("http://localhost:8080/ws");
        const stompClient = new Client({
            webSocketFactory: () => socket,
            connectHeaders: { Authorization: `Bearer ${token}` },
            reconnectDelay: 5000,
            onConnect: () => {
                setIsConnected(true);
                stompClient.subscribe(`/topic/chat/${chatRoomId}`, (message) => {
                    const receivedMsg = JSON.parse(message.body);
                    setMessages((prev) => [...prev, receivedMsg]);
                });
            },
            onStompError: (frame) => console.error("STOMP error:", frame),
        });

        stompClient.activate();
        stompClientRef.current = stompClient;

        return () => stompClient.deactivate();
    }, [chatRoomId]);

    useEffect(() => {
        messageEndRef.current?.scrollIntoView({ behavior: "auto" });
    }, [messages]);

    const handleSend = () => {
        if (!isConnected || !inputMessage.trim()) return;

        const payload = { content: inputMessage };

        stompClientRef.current.publish({
            destination: `/app/${chatRoomId}/send`,
            body: JSON.stringify(payload),
        });

        setInputMessage("");
    };

    // 조합 시작/종료 핸들러
    const handleComposition = (e) => {
        if (e.type === "compositionstart") {
            isComposing.current = true;
        } else if (e.type === "compositionend") {
            isComposing.current = false;
        }
    };

    // 엔터키 핸들러 수정
    const handleKeyDown = (e) => {
        if (e.key === "Enter" && !isComposing.current) {
            e.preventDefault();
            handleSend();
        }
    };

    return (
        <div className="flex flex-col h-screen pt-16 pb-16 bg-gray-50">
            <div className="flex-1 overflow-y-auto px-4 py-2">
                {messages.map((msg) => {
                    const isMyMessage = msg.senderNickname === currentUserNickname;
                    const formattedTime = new Date(msg.timestamp).toLocaleTimeString([], {
                        hour: "2-digit",
                        minute: "2-digit",
                    });

                    return (
                        <div key={msg.id} className={`mb-4 flex ${isMyMessage ? 'justify-end' : 'justify-start'}`}>
                            <div className={`flex flex-col ${isMyMessage ? 'items-end' : 'items-start'}`}>
                                {!isMyMessage && (
                                    <span className="text-xs font-medium text-gray-700 mb-1">
                                        {msg.senderNickname}
                                    </span>
                                )}
                                <div
                                    className={`flex items-end ${isMyMessage ? "justify-end" : "justify-start"} gap-1`}>
                                    {isMyMessage && (
                                        <span className="text-xs text-gray-400 whitespace-nowrap">{formattedTime}</span>
                                    )}
                                    <div
                                        className={`flex px-3 py-2 max-w-[70%] shadow-sm rounded-lg ${
                                            isMyMessage
                                                ? "bg-[#9cb4cd] text-white justify-end"
                                                : "bg-white text-gray-800 border border-gray-200 justify-start"
                                        }`}
                                    >
                                        {msg.content}
                                    </div>
                                    {!isMyMessage && (
                                        <span className="text-xs text-gray-400 whitespace-nowrap">{formattedTime}</span>
                                    )}
                                </div>
                            </div>
                        </div>
                    );
                })}
                <div ref={messageEndRef}/>
            </div>

            <div className="p-3 bg-white border-t">
                <div className="flex items-center">
                    <input
                        type="text"
                        className="flex-grow border rounded-l-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-[#9cb4cd]"
                        placeholder="메시지를 입력하세요"
                        value={inputMessage}
                        onChange={(e) => setInputMessage(e.target.value)}
                        onKeyDown={handleKeyDown}
                        onCompositionStart={handleComposition} // 조합 시작 시
                        onCompositionEnd={handleComposition}   // 조합 종료 시
                    />
                    <button
                        onClick={handleSend}
                        disabled={!isConnected}
                        className="bg-[#9cb4cd] text-white rounded-r-lg px-4 py-2 hover:bg-[#88a8c6]"
                    >
                        전송
                    </button>
                </div>
            </div>
        </div>
    );
};

export default ChatRoomPage;