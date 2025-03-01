
NPCDialogueSystem = {}
NPCDialogueSystem.Data = {}


function NPCDialogueSystem.SayDialoguePhrase(npc, category, chance, color)
    if ZombRand(0, 101) < chance then
        npc:Say(NPCDialogueSystem.Data[category][ZombRand(1, #NPCDialogueSystem.Data[category] + 1)], color)
    end
end

--------------------------------------------

NPCDialogueSystem.Data.smallTalk = {
    {
        "?**??!@@#&?* $$##%?*$ !?$***?#%@",
        "#&$#$&!?$#?*",
        "#??%%!&&*?$ %@&@",
        "%?#*$#!?#$$**",
        "$*%!*?%&?",
        "#@@!%?%&$$#&"
    }
}

NPCDialogueSystem.Data.friendFirstMeet = {
    "Hey! Mind helping me out?",
    "I don't know you, but look's like we're surviving together.",
    "You seem okay, as long as you don't stab me in the back...",
    "Oh thank goodness! A nice person for once!",
    "Pardon me, just helping myself here...",
    "Oh.. Hello, didn't mean to startle you!",
    "I almost punched your lights out partner! Don't sneak up on me!",
    "Woah! I don't want to hurt you, let me be!",
    "I am starving... please... help me.",
    "Don't hurt me! I have nothing!",
    "I'm so thirsty... I need water...",
    "Hey, I'm hurting pretty bad; got a bandage?",
    "I have no idea where I am or what to do... could you help?"
}

NPCDialogueSystem.Data.returnToBase = {
    "Home, sweet home..."
}

NPCDialogueSystem.Data.angryFirstMeet = {
    "You want my stuff? Come get it!",
    "Oh you wanted this loot? That sucks.",
    "Back up or you'll regret it!",
    "You wanna die partner...?",
    "HAHAHAHAHAHAHAHAHA COME HERE!",
    "Look, I don't have much but I'll fight if I have to!",
    "You seem to have some really nice stuff on you...",
    "What a shame... another soon to be dead peasant!",
    "I'd rather die a raider than be a zed!",
    "This is your last chance!",
    "Drop your loot now!",
    "Go ahead and run, makes things more fun for me!",
    "You are being robbed partner, drop it all!"
}

NPCDialogueSystem.Data.meetAfterLongBreak = {
    "Hey! Long time no see... haha",
    "For a second I thought you got eaten, whew...",
    "Cool you came back! I was getting scared...",
    "Nice gear! Starting to look like a killer already.",
    "About time, I was getting tired...",
    "Yay you're back... and there you go again...",
    "We heading out sometime soon?",
    "*sneeze* I'm okay I promise! Must be the weather..."
}

NPCDialogueSystem.Data.friendByeBye = {
    "Come through anytime.",
    "Have a good day.",
    "Its been real homie.",
    "Toodles!",
    "Have a nice life.",
    "Lets do cocaine next time!"
}

NPCDialogueSystem.Data.angryByeBye = {
    "You got fucked up!",
    "Stop crying you big baby..",
    "Oh, okay then...",
    "Keep walking partner...",
    "I'll be back bitch!",
    "Next time I will destroy you.",
    "See, I told you not to fuck with me."
}

NPCDialogueSystem.Data.friendWarning = {
    "Look I dont wanna hurt you...",
    "I have this whole place surrounded, dont try me!",
    "Two options... you walk away or I make you walk.",
    "You wanna fuck on me? I think not.",
    "OooOOoohh I can play dirty too.",
    "I just got right with Jesus; dont do this.",
    "I have an offer you can't refuse...",
    "Oh, honey bless your heart.",
    "You on the wrong side of town buddy...",
    "You should be careful around here mate...",
}

NPCDialogueSystem.Data.angryWarning = {
    "I got both ways.",
    "I already told you once bitch...",
    "Post up fuckface!",
    "Say hello to my little friend!",
    "Pop off mate, do it...",
    "Wanna clap cheeks?! ",
}

NPCDialogueSystem.Data.friendRandomTalk = {
    "There has to be a police station nearby, should we check?",
    "I'm starting to run low on grub, lets find something to eat?",
    "Earlier I bumped into a crazed santa with a saw... He was eaten.",
    "I wonder what happened to the governer...?",
    "We don't need ANY military!",
    "Do you hear that? Sounds like a horde nearby...",
    "Woah... is that a helicopter? Should we run?", --(Says this when normal or EHE heli appears)
    "Sometimes... I dream about cheese.",
    "Makes you wonder what happened to Texas during all this...",
    "I hope my family is okay...",
    "Hmm...",
    "You need something partner?",
    "Damn that food I ate earlier isn't settling...",
    "I feel weird... like someone is watching us...",
    "You woulnd't happen to have some rope do you?",
    "I wonder what the rest of the states are like with this going on...",
    "Isn't it interesting how the military is not here but everywhere else?",
    "Either we'll be rescued... or the new government will be nudist bandits...",
    "See that car over there? Maybe it works!"
}

NPCDialogueSystem.Data.angryRandomTalk = {
    "Hey! The fuck you think you doing?",
    "This should be fun...",
    "Back it up partner!",
    "... I guess the eager death smile didnt stir you away.",
    "Halt!",
    "Get back here chump!",
    "Your flesh will be delicious between some rye bread!",
    "Give me that ass!",
    "Is there a reason were speaking? Do you really want to die?",
    "Um... hello there fellow bandit?",
    "*Smokes blunt* Once I'm finished with this... your head is mine!",
    "You must be bored or drastically stupid...",
    "You want food? Here! *Throws rotten flesh*",
    "Guess I got myself a meal!",
    "Partner... you are in the wrong county...",
    "I hope my buddy is back from his break... I cant raid by myself...",
    "You interested in joining a killer huh?",
    "Y'know... I just broke out from Rosewood Prison...",
    "That's a nice boulder...",
    "Gimme that booty!",
    "You got a puurdy mouth!",
    "Ill beat a mother fucker; with a mother fucker.",
    "Wanna get probed?",
    "Well I guess it's the day that bitches die..."
}

NPCDialogueSystem.Data.attackTalk = {
    "Hey! Back up chompy!",
    "Damn... you were my teacher back in grade school...",
    "Wow! I know you! Fuck you for that fender bender!",
    "I think I used to know them... goodness...",
    "God help us! ",
    "Bless me with strength!",
    "Ew... you are drooling brains sir.",
    "Never thought I'd have fun bashing in skulls..."
}

NPCDialogueSystem.Data.fleeTalk = {
    "No! Get away!",
    "No No No No No No No No",
    "Oh shit... Help!",
    "Pfft fuck all that...",
    "Yeah... I'll pass, have fun partner.",
    "Um... I'm just gonna dip.",
    "Deuces!",
    "They're gonna get me!",
    "NOOOOO!! I'm to pretty to die!",
    "Oh hell nah i just did my hair."
}