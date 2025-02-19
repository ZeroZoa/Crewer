import React, { useEffect, useState } from "react";
import {useNavigate } from "react-router-dom";
import { Plus } from "lucide-react";

const ChatRoomListPage = () => {
    const [rooms, setRooms] = useState([]);
    const [showModal, setShowModal] = useState(false);
    const navigate = useNavigate();

    useEffect(() => {
        const fetchRooms = async () => {
            try {
                const response = await fetch("http://localhost:8080/chat/room");
                if (response.ok) {
                    let data = await response.json();
                    console.log("채팅방 데이터:", data);
                    setRooms(data);
                } else {
                    console.error("Failed to fetch chat rooms");
                }
            } catch (error) {
                console.error("Error fetching chat rooms:", error);
            }
        };

        fetchRooms();
    }, []);

    const createRoom = (type) => {
        navigate(`/chat/room/create?type=${type}`);
    };

    return (
        <div className="min-h-screen flex flex-col items-center w-full bg-gray-100">
            <div className="bg-white shadow-lg shadow-blue-200 rounded-lg p-4 w-full max-w-3xl flex-grow">
                {rooms.map((room) => (
                    <div
                        key={room.id}
                        className="bg-white py-5 px-7 rounded-xl shadow-blue-200 shadow-2xl cursor-pointer transition relative mb-3"
                        onClick={() => navigate(`/chat/${room.id}`)}
                    >
                        <div className="flex flex-col items-start -mt-2 -ml-2">
                            <h2 className="text-xl font-bold">{room.name}</h2>
                            <h2>asd</h2>
                            <p className="text-gray-600 text-sm">참여자: {room.participants}명</p>
                        </div>
                    </div>
                ))}
            </div>

            {/* 플로팅 버튼 */}
            <button
                onClick={() => setShowModal(true)}
                className="fixed bottom-20 right-6 border-4 border-[#9cb4cd] bg-transparent text-[#9cb4cd] w-16 h-16 rounded-full flex items-center justify-center shadow-xl hover:bg-[#9cb4cd] hover:text-white focus:outline-none focus:ring-2 focus:ring-[#9cb4cd]"
            >
                <Plus className="w-9 h-9" />
            </button>

            {/* 모달 창 */}
            {showModal && (
                <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50">
                    <div className="bg-white p-6 rounded-lg shadow-lg w-80">
                        <h2 className="text-lg font-bold mb-4">채팅방 유형 선택</h2>
                        <button onClick={() => createRoom("PRIVATE")} className="w-full bg-[#9cb4cd] text-black py-2 rounded mb-2">1:1 채팅</button>
                        <button onClick={() => createRoom("GROUP")} className="w-full bg-[#9cb4cd] text-black py-2 rounded">팀 채팅</button>
                        <button onClick={() => setShowModal(false)} className="w-full bg-gray-300 text-black py-2 rounded mt-2">닫기</button>
                    </div>
                </div>
            )}
        </div>
    );
};

export default ChatRoomListPage;
