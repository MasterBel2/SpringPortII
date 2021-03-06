//
//  BattleListController.swift
//  SpringPort II
//
//  Created by MasterBel2 on 25/3/17.
//  Copyright © 2017 MasterBel2. All rights reserved.
//

import Cocoa

protocol BattleListControllerDelegate: ServerCommandRouter {
    func request(toJoin battle: String, with password: String)
    func didJoin(_ battle: Battle)
    func didLeaveBattle()
}

protocol BattleListDataSource: class {
    func battleCount() -> Int
    func openBattleCount() -> Int
    func battle(for indexPath: IndexPath) -> Battle
    func openBattle(for indexPath: IndexPath) -> Battle
    func founder(for battle: Battle) -> User
    func request(toJoin battle: String, with password: String)
	func has(engine version: String) -> Bool
	func hasMap(with checksum: Int32) -> Bool
	func has(_ game: String/*, versioned version: String*/) -> Bool
}

protocol BattleListDataOutput: class {
    func reloadBattleListData()
}

class BattleListController: ServerBattleListDelegate, BattleListDataSource {
    weak var delegate: BattleListControllerDelegate!
	weak var cache: Cache?
    var outputs: [BattleListDataOutput] = []
    var battles: [Battle] = []
    
    func server(_ server: TASServer, didOpen battle: Battle) {
        battles.append(battle)
        battleUpdated()
    }
    func server(_ server: TASServer, didCloseBattleWithId battleId: String) {
        battles = battles.filter {$0.battleId != battleId}
        battleUpdated()
    }
    func server(_ server: TASServer, didUpdate battleInfo: UpdatedBattleInfo) {
        let battleId = battleInfo.battleId
        battles
            .filter {$0.battleId == battleId}
            .forEach { battle in
                battle.updateBattle(withInfo: battleInfo)
        }
        battleUpdated()
    }
	
    func server(_ server: TASServer, userNamed name: String, didJoinBattleWithId battleId: String) {
        battles
            .filter { $0.battleId == battleId }
            .forEach { battle in
                battle.players.append(name)
                battle.updateNumberOfPlayers()
        }
        battleUpdated()
    }
    func server(_ server: TASServer, userNamed name: String, didLeaveBattleWithId battleId: String) { // TODO: - ome of this stuff may beed to be moved over to the Battleroom Controller.
        if name == delegate?.myUsername() {
            delegate?.didLeaveBattle()
        }
        
        battles
            .filter {$0.battleId == battleId}
            .forEach { battle in
                battle.players = battle.players.filter {$0 != name}
                battle.updateNumberOfPlayers()
        }
        battleUpdated()
    }
    func server(_ server: TASServer, didAcceptJoinOf battleID: String, withHash hash: String) {
        
        battles
            .filter { $0.battleId == battleID }
            .forEach { battle in
                delegate?.didJoin(battle) // !!!!
        }
    }
    
    func battleUpdated() {
        battles.sort { $0.playerCount > $1.playerCount }
        for output in outputs {
            output.reloadBattleListData()
        }
    }
    //////////////////////////////////
    // MARK: - BattleListDataSource //
    //////////////////////////////////
    func battleCount() -> Int {
        return battles.count
    }
    
    func battle(for indexPath: IndexPath) -> Battle {
        return battles[indexPath.item]
    }
    func founder(for battle: Battle) -> User {
        let username = battle.founder
		guard let user = delegate?.find(user: username) else {
			fatalError("Fatal Error: Cannot find host's user object.")
		}
		return user
    }
    
    func request(toJoin battle: String, with password: String) {
        delegate?.request(toJoin: battle, with: password)
    }
    
    // Mark: -- Open Battles Only
    
    func openBattleCount() -> Int {
        let filteredBattles = battles.filter {$0.playerCount > 0}
        return filteredBattles.count
    }
    
    func openBattle(for indexPath: IndexPath) -> Battle {
        let filteredBattles = battles.filter {$0.playerCount > 0}
        return filteredBattles[indexPath.item]
    }
	
	func has(engine version: String) -> Bool {
		return cache?.has(version) ?? false
	}
	
	func hasMap(with checksum: Int32) -> Bool {
		return cache?.hasMap(with: checksum) ?? false
	}
	
	func has(_ game: String/*, versioned version: String*/) -> Bool {
		return false
//		return cache?.has(gameName, versioned: version) ?? false
	}
	
}
