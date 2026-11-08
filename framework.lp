% =========================================================================
% Retraction of erroneous truths: generic rules
% Two-step decisions, the disconfirm performative, statuses of past
% assertions, and moral evaluation at step 1.
%
% Utterances utter(X,Y,N,...) are indexed by the step N (0 or 1) at which
% they are made. A scenario file must provide: decider/1, base/1, base_at/2
% (step, base), holds/2, sit/1, do/2, the causal theory as ev/3, its own
% choices as trig/3, offers/2 and bounds/3, and utility/2.
% =========================================================================

% ---------- Steps and evaluation -----------------------------------------
step(U,N) :- do(_,U), U = utter(_,_,N,_).

sat(B,S,X) :- base(B), sit(S), holds(B,X).
sat(B,S,X) :- ev(B,S,X).

% ---------- Retraction choice --------------------------------------------
% One choice per addressee q and content sigma, written ret(Q,X):
% gamma_ret(q,sigma) <- utter(a,q,0,inform(sigma)) & credible(sigma,q) & not sigma
% gamma_ret(q,sigma) =  < {utter(a,q,1,disconfirm(sigma))}, 0, 1 >
trig(B,S,ret(Q,X)) :- base(B), decider(A), do(S,utter(A,Q,0,inform(X))),
                      sat(B,S,credible(X,Q)), not sat(B,S,X).
offers(ret(Q,X), utter(A,Q,1,disconfirm(X))) :-
                      decider(A), do(_,utter(A,Q,0,inform(X))).
bounds(ret(Q,X),0,1) :- offers(ret(Q,X),_).

% ---------- Admissibility (coverage and cardinality) ---------------------
covered(B,S,A)   :- do(S,A), trig(B,S,G), offers(G,A).
uncovered(B,S,A) :- base(B), do(S,A), not covered(B,S,A).
card(B,S,G,N)    :- trig(B,S,G), N = #count{ A : do(S,A), offers(G,A) }.
badcard(B,S,G)   :- card(B,S,G,N), bounds(G,Mn,_), N < Mn.
badcard(B,S,G)   :- card(B,S,G,N), bounds(G,_,Mx), N > Mx.
admissible(B,S)  :- base(B), sit(S), not uncovered(B,S,_), not badcard(B,S,_).

% Every candidate decision at step 1 must be admissible for the step-1 base.
:- sit(S), base_at(1,B), not admissible(B,S).

% ---------- Epistemic types, fixed at the step of utterance --------------
% Honesty uses the base of the step of utterance (Definition 1). Contents are
% evaluated in the step-1 situation, which coincides with D_N whenever the
% content is a context atom, as in the case study.
honest(S,U)    :- do(S,U), decider(A), U = utter(A,_,_,inform(X)),
                  step(U,K), base_at(K,B), sat(B,S,X).
dishonest(S,U) :- do(S,U), decider(A), U = utter(A,_,_,inform(X)),
                  step(U,K), base_at(K,B), not sat(B,S,X).
honest(S,U)    :- do(S,U), decider(A), U = utter(A,_,_,disconfirm(X)),
                  step(U,K), base_at(K,B), not sat(B,S,X).
dishonest(S,U) :- do(S,U), decider(A), U = utter(A,_,_,disconfirm(X)),
                  step(U,K), base_at(K,B), sat(B,S,X).
truth(S,U)     :- do(S,U), decider(A), U = utter(A,_,_,inform(X)), sat(env,S,X).
falsity(S,U)   :- do(S,U), decider(A), U = utter(A,_,_,inform(X)), not sat(env,S,X).

type(S,U,objective_truth) :- honest(S,U),    truth(S,U).
type(S,U,erroneous_truth) :- honest(S,U),    falsity(S,U).
type(S,U,objective_lie)   :- dishonest(S,U), falsity(S,U).
type(S,U,erroneous_lie)   :- dishonest(S,U), truth(S,U).

% ---------- Status of a past assertion at step 1 -------------------------
% Statuses are indexed by addressee Q and content X (Definition 2).
maintained(S,Q,X)  :- decider(A), do(S,utter(A,Q,0,inform(X))),
                      base_at(1,B), sat(B,S,X).
retracted(S,Q,X)   :- base_at(1,B), trig(B,S,ret(Q,X)),
                      decider(A), do(S,utter(A,Q,1,disconfirm(X))).
not_re(S,Q,X)      :- base_at(1,B), trig(B,S,ret(Q,X)), not retracted(S,Q,X).

% ---------- Utility ------------------------------------------------------
util(S,B,U) :- sit(S), base(B), U = #sum{ V,E : ev(B,S,E), utility(E,V) }.

% ---------- Deontologism -------------------------------------------------
% m1: honesty maxim (original framework); m2: persistent honesty maxim.
violated(S,m1) :- dishonest(S,_).
violated(S,m2) :- not_re(S,_,_).
verdict(S,M,ok) :- sit(S), M = (m1;m2), not violated(S,M).
verdict(S,M,ko) :- violated(S,M), M = (m1;m2).

% ---------- Consequentialism ---------------------------------------------
% c1: expected utility (step-1 base); c2: actual utility (environment).
ref(c1,B) :- base_at(1,B).
ref(c2,env).
best(T,M) :- ref(T,B), M = #max{ U,S : util(S,B,U) }.
verdict(S,T,ok) :- ref(T,B), util(S,B,U), best(T,U).
verdict(S,T,ko) :- ref(T,B), util(S,B,U), best(T,M), U < M.

#show type/3.
#show maintained/3.
#show retracted/3.
#show not_re/3.
#show util/3.
#show verdict/3.
