import React from "react";
import { NavLink } from "react-router-dom";
import { Home, MapPin, BarChart, MessageCircle, User } from "lucide-react";

const BottomNav = () => {
    return (
        <nav className="fixed bottom-0 left-0 w-full bg-white border-t border-gray-300">
            <div className="flex justify-around py-3">
                {/* 홈 */}
                <NavLink
                    to="/"
                    className={({ isActive }) =>
                        `flex flex-col items-center text-sm ${
                            isActive ? "text-black" : "text-[#9cb4cd]"
                        }`
                    }
                >
                    <Home className="w-6 h-6" />
                    <span>홈</span>
                </NavLink>

                {/* 지도 (추후 기능 추가 예정) */}
                <NavLink
                    to="/map"
                    className={({ isActive }) =>
                        `flex flex-col items-center text-sm ${
                            isActive ? "text-black" : "text-[#9cb4cd]"
                        }`
                    }
                >
                    <MapPin className="w-6 h-6" />
                    <span>지도</span>
                </NavLink>

                {/* 랭킹 (추후 기능 추가 예정) */}
                <NavLink
                    to="/ranking"
                    className={({ isActive }) =>
                        `flex flex-col items-center text-sm ${
                            isActive ? "text-black" : "text-[#9cb4cd]"
                        }`
                    }
                >
                    <BarChart className="w-6 h-6" />
                    <span>랭킹</span>
                </NavLink>

                {/* 채팅 (추후 기능 추가 예정) */}
                <NavLink
                    to="/chat/room"
                    className={({ isActive }) =>
                        `flex flex-col items-center text-sm ${
                            isActive ? "text-black" : "text-[#9cb4cd]"
                        }`
                    }
                >
                    <MessageCircle className="w-6 h-6" />
                    <span>채팅</span>
                </NavLink>

                {/* 프로필 */}
                <NavLink
                    to="/profile/me"
                    className={({ isActive }) =>
                        `flex flex-col items-center text-sm ${
                            isActive ? "text-black" : "text-[#9cb4cd]"
                        }`
                    }
                >
                    <User className="w-6 h-6" />
                    <span>프로필</span>
                </NavLink>
            </div>
        </nav>
    );
};

export default BottomNav;