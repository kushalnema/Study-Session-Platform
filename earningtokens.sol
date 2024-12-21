// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StudyToken is ERC20 {
    constructor() ERC20("StudyToken", "STDY") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}

contract StudySessionPlatform {
    StudyToken public token;

    struct Session {
        address host;
        string topic;
        uint startTime;
        uint duration;
        uint rewardPool;
        uint participantsCount;
        bool completed;
    }

    mapping(uint => Session) public sessions;
    mapping(uint => address[]) public sessionParticipants;
    uint public sessionIdCounter;

    event SessionCreated(uint sessionId, address host, string topic, uint rewardPool);
    event ParticipantJoined(uint sessionId, address participant);
    event SessionCompleted(uint sessionId);

    constructor(address _tokenAddress) {
        token = StudyToken(_tokenAddress);
    }

    function createSession(string calldata topic, uint startTime, uint duration, uint rewardPool) external {
        require(startTime > block.timestamp, "Start time must be in the future");
        require(rewardPool > 0, "Reward pool must be greater than 0");

        token.transferFrom(msg.sender, address(this), rewardPool);

        sessions[sessionIdCounter] = Session({
            host: msg.sender,
            topic: topic,
            startTime: startTime,
            duration: duration,
            rewardPool: rewardPool,
            participantsCount: 0,
            completed: false
        });

        emit SessionCreated(sessionIdCounter, msg.sender, topic, rewardPool);
        sessionIdCounter++;
    }

    function joinSession(uint sessionId) external {
        Session storage session = sessions[sessionId];
        require(block.timestamp < session.startTime, "Session has already started");
        require(!session.completed, "Session is already completed");

        sessionParticipants[sessionId].push(msg.sender);
        session.participantsCount++;

        emit ParticipantJoined(sessionId, msg.sender);
    }

    function completeSession(uint sessionId) external {
        Session storage session = sessions[sessionId];
        require(msg.sender == session.host, "Only the host can complete the session");
        require(block.timestamp >= session.startTime + session.duration, "Session is still ongoing");
        require(!session.completed, "Session is already completed");

        uint rewardPerParticipant = session.rewardPool / session.participantsCount;

        for (uint i = 0; i < sessionParticipants[sessionId].length; i++) {
            token.transfer(sessionParticipants[sessionId][i], rewardPerParticipant);
        }

        session.completed = true;

        emit SessionCompleted(sessionId);
    }
}
