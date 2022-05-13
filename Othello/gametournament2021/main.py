from game import Game
from random_agent import RandomAgent
from markov_agent import MarkovAgent
from minimax_agent import MinimaxAgent
from AlphaT2 import Agent as BAgent
from AlphaT1 import Agent as AAgent
from AlphaT import Agent as TAgent


def main():
    # game = Game(RandomAgent(), MarkovAgent())
    # game = Game(RandomAgent(), MinimaxAgent(4))
    # game = Game(MarkovAgent(), MinimaxAgent(4))
    wintimes = 0
    for i in range(20):
        game = Game(AAgent(), TAgent())
        winner = game.play(output=True, timeout_per_turn=5.0)
        if winner == 2:
            wintimes += 1

    print(wintimes)

if __name__ == "__main__":
    main()

