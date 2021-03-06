//
//  Pokemon.swift
//  jPokedex
//
//  Created by Jeane Carlos on 7/4/17.
//  Copyright © 2017 Jeane Carlos. All rights reserved.
//

import Foundation
import Alamofire

class Pokemon {
    private var _name: String!
    private var _pokedexId: Int!
    private var _description: String!
    private var _type: String!
    private var _defense: String!
    private var _weight: String!
    private var _height: String!
    private var _attack: String!
    private var _pokemonURL: String!
    
    private var _nextEvoId = ""
    private var _nextEvolutionTxt: String = ""
    private var _nextPokemon: String = ""
    private var _evolvable = false
    private var evolutions = [Pokemon]()
    private var evoIds = [String]() //This is an array that was designed to track duplicates
    
    
    
    var evolvable: BooleanLiteralType {
        if _evolvable {
            _evolvable = true
        } else {
            _evolvable = false
        }
        return _evolvable
    }
    
    
    var nextPokemon: String {
        return _nextPokemon
    }
    var description: String {
        if _description == nil {
            _description = ""
        }
        return _description
    }
    
    var type: String {
        if _type == nil {
            _type = ""
        }
        return _type
    }
    
    var defense: String {
        if _defense == nil {
            _defense = ""
        }
        return _defense
    }
    
    var weight: String {
        if _weight == nil {
            _weight = ""
        }
        return _weight
    }
    
    var height: String {
        if _height == nil {
            _height = ""
        }
        return _height
    }
    
    var attack: String {
        if _attack == nil {
            _attack = ""
        }
        
        return _attack
    }
    
    var name: String {
        return _name
    }
    
    var pokedexId: Int {
        return _pokedexId
    }
    
    var nextEvoId: String {
        return _nextEvoId
    }
    
    var nextEvolutionTxt: String {
        if !self._evolvable {
            _nextEvolutionTxt = "There Is No Further Evolution"
        } else {
            _nextEvolutionTxt = "The Next Evolution Is " + _nextPokemon
        }
        
        return _nextEvolutionTxt
    }
    
    init(name: String, pokedexId: Int) {
        self._name = name
        self._pokedexId = pokedexId
        
        self._pokemonURL = "\(URL_BASE)\(URL_POKEMON)\(self.pokedexId)"
    }
    
    func downloadPokemonDetail(completed: @escaping DownloadComplete) {
        Alamofire.request(_pokemonURL).responseJSON { (response) in
            if let dict = response.result.value as? Dictionary<String, Any> {
                if let weight = dict["weight"] as? String {
                    self._weight = weight
                }
                
                if let height = dict["height"] as? String {
                    self._height = height
                }
                
                if let attack = dict["attack"] as? Int {
                    self._attack = String(attack)
                }
                
                if let defense = dict["defense"] as? Int {
                    self._defense = String(defense)
                }
                
                //This focuses on getting each type
                //As of the first version of the API, a pokemon can only have two types
                if let types = dict["types"] as? [Dictionary<String, String>] {
                    if types.count == 2 {
                        let type1 = types[0]["name"]?.capitalized
                        let type2 = types[1]["name"]?.capitalized
                        self._type = "\(type1 ?? "None")\\\(type2 ?? "None")"
                        //Unfortunately this part of the code has no protection, but it should be there
                        
                    } else {
                        // This assumes the pokemon has one type
                        if let type1 = types[0]["name"] {
                            self._type = type1.capitalized
                        }
                        
                    }
                }
                
                //This is the part of the code that focuses on the Pokemon's next evolution
                if let evolution = dict["evolutions"] as? [Dictionary<String, Any>] {
                    if evolution.isEmpty {
                        self._evolvable = false
                    } else {
                        let nextEvolution = evolution[0]["to"] as? String
                        if nextEvolution?.range(of:"mega") != nil {
                            self._evolvable = false //This is a mega evolution, and we don't have the data for that yet
                        } else {
                            //It does have an evolution that is not mega
                            self._evolvable = true
                            
                            for evo in evolution {
                                let nextEvo = evo["to"]
                                var nextEvoId = ""
                                if let nextId = evo["resource_uri"] as? String {
                                    
                                    
                                    let start = nextId.index(nextId.startIndex, offsetBy: 16) // 16 is it
                                    let end = nextId.index(nextId.endIndex, offsetBy: -1)
                                    let range = start..<end
                                    nextEvoId = nextId.substring(with: range)
                                    
                                    if !self.evoIds.contains(nextEvoId){
                                        //The ID isn't already contained. This is added because the POKEAPI has duplicate evolutions for instance Ivysaur has seperate evolution items called Venasaur and Venasaur
                                        let poke = Pokemon(name: nextEvo as! String, pokedexId: Int(nextEvoId)!)
                                        self.evoIds.append(nextEvoId)
                                        self.evolutions.append(poke)
                                    }
                                }
                            }
                            print(self.evolutions)
                            
                            
                            // Keep for now
                            if let nextEvolution = evolution[0]["to"] as? String {
                                self._nextPokemon = nextEvolution
                                //This is a very bad way to mention the next evolution because a pokemon may have more than one evolution from it's original form. An updated method will take this into consideration and also how a pokemon evolves
                            }
                            
                            if let nextId = evolution[0]["resource_uri"] as? String {
                                let start = nextId.index(nextId.startIndex, offsetBy: 16) // 16 is it
                                let end = nextId.index(nextId.endIndex, offsetBy: -1)
                                let range = start..<end
                                self._nextEvoId = nextId.substring(with: range)
                                //Consdering the string comes like "/api/v1/pokemon/197/"
                                //This cuts off one from the right and 16 from the left
                            }
                            // End Keep for now
                            
                        }
                        
                    }
                    
                }
                
                //This focuses on getting a description
                if let description = dict["descriptions"] as? [Dictionary<String, String>] {
                    if let url = description[0]["resource_uri"] {
                        let descURL = "\(URL_BASE)\(url)"
                        //We are going to parse another JSON file within this parse because the description is not in the file itself. Instead only the URL of where to find the description is. So we use that url to access another JSON file with the description we are looking for
                        Alamofire.request(descURL).responseJSON(completionHandler: { (response) in
                            if let descDict = response.result.value as? Dictionary<String, AnyObject> {
                                if let description = descDict["description"] as? String {
                                    let newDescription = description.replacingOccurrences(of: "POKMON", with: "Pokemon")
                                    self._description = newDescription
                                    //The api calls pokemon "POKMON", so we replace this with something more friendly
                                }
                            }
                            completed()
                        })
                        
                    }
                } else {
                    self._description = ""
                }
                
            }
            completed()
        }
    }
}

