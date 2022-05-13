from othello import OthelloState
from agent_interface import AgentInterface
from game import Game
from random_agent import RandomAgent
import numpy as np


class Agent(AgentInterface):
    """
    Implemented the Monte Carlo Tree Search algorithm which described in lecture slides combined with Bayesian theory
    The basic idea is to think of a simulation in MCTS as a sampling
    Using a heuristic equation as a hyperparameter for the prior distribution
    The Likelihood is a Bernoulli distribution, follow the Bayesian theory, the posterior distribution is still a Beta distribution
    Base on the sample result, we will get the posterior alpha and beta, so we use (alpha-beta)/(alpha+beta) to represent the relatively part in UCB1
    Firsly, I only use the square_weight to construct the alpha and beta, but new agent cannot beat the MCTS agent, so I add the actions in hyperparameter
    The simulation part cost a lot of time, especially in the early stage. But in the earlier stage, the game situation is always systematic.
    I think simulation on a systematic situation is useless, so I only simulation an expansion when its counts over 8. In the earlier select part, I only rely on my heuristic function.
    In order to avoid timeout, the agent will yield action base on the visited times each 10 trials
    An agent who plays the Othello game

    Methods
    -------
    `info` returns the agent's information
    `decide` chooses an action from possible actions

    """

    def __init__(self):
        self.Q = dict()  # total win times of each state
        self.N = dict()  # total visit times of each state
        self.children = dict()  # children of each state
        self.trials = 0
        self.deepth = 0
        self.__simulator = Game(RandomAgent(), RandomAgent())
        self.square_weight = [
            8, 1, 6, 6, 6, 6, 1, 8,
            1, 0, 3, 3, 3, 3, 0, 1,
            6, 3, 5, 4, 4, 5, 3, 6,
            6, 3, 4, 5, 5, 4, 3, 6,
            6, 3, 4, 5, 5, 4, 3, 6,
            6, 3, 5, 4, 4, 5, 3, 6,
            1, 0, 3, 3, 3, 3, 0, 1,
            8, 1, 6, 6, 6, 6, 1, 8,
        ]
        self.prior = dict()  # weight score of each state.grid
        self.player = 0
        self.otherplayer = 0

    @staticmethod
    def info():
        """
        Return the agent's information

        Returns
        -------
        Dict[str, str]
            `agent name` is the agent's name
            `student name` is the list team members' names
            `student number` is the list of student numbers of the team members
        """
        # -------- Task 1 -------------------------
        # Please complete the following information

        return {"agent name": "AlphaT",  # COMPLETE HERE
                "student name": ["Rongzhi Liu"],  # COMPLETE HERE
                "student number": ["877152"]}  # COMPLETE HERE

    def decide(self, state: OthelloState, actions: list):
        """
        Generate a sequence of increasingly preferable actions

        Given the current `state` and all possible `actions`, this function
        should choose the action that leads to the agent's
        victory.
        However, since there is a time limit for the execution of this function,
        it is possible to choose a sequence of increasing preferable actions.
        Therefore, this function is designed as a generator; it means it should
        have no return statement, but it should `yield` a sequence of increasing
        good actions.

        IMPORTANT: If no action is yielded within the time limit, the game will
        choose a random action for the player.

        Parameters
        ----------
        state: OthelloState
            Current state of the board
        actions: list
            List of all possible actions

        Yields
        ------
        action
            the chosen `action`
        """
        # -------- TASK 2 ------------------------------------------------------
        # Your task is to implement an algorithm to choose an action form the
        # given `actions` list. You can implement any algorithm you want.
        # However, you should keep in mind that the execution time of this
        # function is limited. So, instead of choosing just one action, you can
        # generate a sequence of increasing good action.
        # This function is a generator. So, you should use `yield` statement
        # rather than `return` statement. To find more information about
        # generator functions, you can take a look at:
        # https://www.geeksforgeeks.org/generators-in-python/
        #
        # If you generate multiple actions, the last action will be used in the
        # game.
        #
        # Tips
        # ====
        # 1. During development of your algorithm, you may want to find the next
        #    state after applying an action to the current state; in this case,
        #    you can use the following patterns:
        #    `next_state = current_state.successor(action)`
        #
        # 2. If you need to simulate a game from a specific state to find the
        #    the winner, you can use the following pattern:
        #    ```
        #    simulator = Game(FirstAgent(), SecondAgent())
        #    winner = simulator.play(starting_state=specified_state)
        #    ```
        #    The `MarkovAgent` has illustrated a concrete example of this
        #    pattern.
        #
        # 3. You are free to choose what kind of game-playing agent you
        #    implement. Some of the obvious approaches are the following:
        # 3.1 Implement alpha-beta (and investigate its potential for searching deeper
        #     than what is possible with Minimax). Also, the order in which the actions
        #     are tried in a given node impacts the effectiveness of alpha-beta: you could
        #     investigate different ways of ordering the actions/successor states.
        # 3.2 Try out better heuristics, e.g. ones that take into account the higher
        #     importance of edge and corner cells. Find material on this in the Internet.
        # 3.3 You could try out more advanced Monte Carlo search methods (however, we do
        #     not know whether MCTS is competitive because of the high cost of the full
        #     gameplays.)
        # 3.4 You could of course try something completely different if you are willing to
        #     invest more time.
        #
        # GL HF :)
        # ----------------------------------------------------------------------

        # Replace the following lines with your algorithm
        self.Q = dict()  # total win times of each state
        self.N = dict()  # total visit times of each state
        self.children = dict()  # children of each state
        self.trials = 0
        self.prior = dict()  # weight score of each state.grid
        self.player = state.player
        self.otplayer = 3 - state.player

        while True:
            # select the state which need to be expanded
            self.trials += 1
            path = self.select(state)
            leaf = self.expand(path[-1])
            if leaf != 0:
                path.append(leaf)

            if path[-1].count(self.player) > 8:
                result = self.simulate(path[-1])
            else:
                result = -1
            self.backpropagate(state, path, result)

            if (self.trials + 1) % 10 == 0:
                visit_times = [0] * len(actions)
                for i, action in enumerate(actions):
                    state0 = state.successor(action)
                    for key in self.N.keys():
                        if state0.grid == key.grid:
                            state0 = key
                    if state0 in self.N.keys():
                        visit_times[i] = self.N[state0]
                yield actions[visit_times.index(max(visit_times))]

    def select(self, state: OthelloState):
        path = []
        self.deepth = 0
        state0 = state
        while True:
            path.append(state0)
            if state0 not in self.children or not self.children[state0]:
                # node is either unexplored or terminal
                return path
            if (len(state0.actions()) - len(self.children[state0])) > 0:
                # node is not explored totally
                return path

            self.deepth += 1
            state0 = self.beyes_select(state0)

    def beyes_select(self, state: OthelloState):
        beyes = dict()
        p = 1
        if self.deepth % 2 == 0:
            p = -1

        actionsN = len(state.actions())

        for node in self.children[state]:
            if tuple(node.grid) not in self.prior.keys():
                self.weighted_score(node, actionsN)

            alpha = self.prior[tuple(node.grid)][0] + self.Q[node]
            beta = self.prior[tuple(node.grid)][1] + self.N[node] - self.Q[node]
            if self.N[node] > 0:
                beyes[node] = p * (alpha - beta) / (alpha + beta) + np.sqrt(
                    2 * np.log(self.trials) / self.N[node])
            else:
                beyes[node] = p * (alpha - beta) / (alpha + beta)

        return max(beyes, key=beyes.get)

    def weighted_score(self, state: OthelloState, actionsN):
        curPlayer = 0
        oppPlayer = 0
        for i in range(len(state.grid)):
            if state.grid[i] == self.player:
                curPlayer += self.square_weight[i]
            elif state.grid[i] == self.otplayer:
                oppPlayer += self.square_weight[i]

        if state.player == self.player:
            curPlayer += len(state.actions()) * 10
            oppPlayer += actionsN * 10
        else:
            curPlayer += actionsN * 10
            oppPlayer += len(state.actions()) * 10

        self.prior[tuple(state.grid)] = [curPlayer / 10, oppPlayer / 10]

    def expand(self, state: OthelloState):
        if state not in self.children.keys():
            self.children[state] = []

        for action in state.actions():
            state0 = state.successor(action)

            for node in self.children[state]:
                if state0.grid == node.grid:
                    state0 = node

            if state0 not in self.children[state]:
                self.children[state].append(state0)
                return state0

        return 0

    def simulate(self, state: OthelloState):
        actions = state.actions()
        if not actions:
            if (not state.previousMoved):
                if (state.count(state.player) >= state.count(state.otherPlayer)):
                    return state.player
                if (state.count(state.player) < state.count(state.otherPlayer)):
                    return state.otherPlayer

        return self.__simulator.play(output=False, starting_state=state)

    def backpropagate(self, state, path, result):
        for node in path:
            if node not in self.N.keys():
                self.N[node] = 0
                self.Q[node] = 0

            if result != -1:
                self.N[node] += 1
                if result == state.player:
                    self.Q[node] += 1
