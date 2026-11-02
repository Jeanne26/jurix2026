% =========================================================================
% Retraction of erroneous truths: generic rules
% Two-step decisions, the disconfirm performative, statuses of past
% assertions, and moral evaluation at step 1.
%
% A scenario file must provide: decider/1, base/1, base_at/2 (step, base),
% round/2 (step, round), holds/2, sit/1, do/2, the causal theory as ev/3,
% its own choices as trig/3, offers/2 and bounds/3, and utility/2.
% =========================================================================

% ---------- Steps and evaluation -----------------------------------------
step(U,K) :- do(_,U), U = utter(_,_,N,_), round(K,N).

sat(B,S,X) :- base(B), sit(S), holds(B,X).
sat(B,S,X) :- ev(B,S,X).

% ---------- Retraction choice --------------------------------------------
% gamma_ret(sigma) <- utter(a,q,N,inform(sigma)) & credible(sigma,q) & not sigma
% gamma_ret(sigma) =  < {utter(a,q,N',disconfirm(sigma))}, 0, 1 >
trig(B,S,ret(Q,X)) :- base(B), decider(A), do(S,utter(A,Q,N,inform(X))),
                      round(0,N), sat(B,S,credible(X,Q)), not sat(B,S,X).
offers(ret(Q,X), utter(A,Q,N1,disconfirm(X))) :-
                      decider(A), do(_,utter(A,Q,N,inform(X))),
                      round(0,N), round(1,N1).
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
maintained(S,X)    :- decider(A), do(S,utter(A,_,N,inform(X))), round(0,N),
                      base_at(1,B), sat(B,S,X).
retracted(S,X)     :- base_at(1,B), trig(B,S,ret(Q,X)),
                      decider(A), do(S,utter(A,Q,_,disconfirm(X))).
left_standing(S,X) :- base_at(1,B), trig(B,S,ret(_,X)), not retracted(S,X).

% ---------- Utility ------------------------------------------------------
util(S,B,U) :- sit(S), base(B), U = #sum{ V,E : ev(B,S,E), utility(E,V) }.

% ---------- Deontologism -------------------------------------------------
% maxim2: instantaneous honesty; maxim3: persistent honesty.
violated(S,maxim2) :- dishonest(S,_).
violated(S,maxim3) :- left_standing(S,_).
verdict(S,m2,ok) :- sit(S), not violated(S,maxim2).
verdict(S,m2,ko) :- violated(S,maxim2).
verdict(S,m3,ok) :- sit(S), not violated(S,maxim3).
verdict(S,m3,ko) :- violated(S,maxim3).

% ---------- Principialism ------------------------------------------------
% principle1/principle2: honesty when uttering; principle3: persistent honesty.
violated(S,principle1) :- dishonest(S,_).
violated(S,principle2) :- dishonest(S,_).
violated(S,principle3) :- left_standing(S,_).

% principialism1: local exception, the addressee does not deserve the truth.
exc(S,p1,principle1) :- violated(S,principle1), dishonest(S,U),
                        U = utter(_,Q,_,_), step(U,K), base_at(K,B),
                        holds(B,murderer(Q)).
exc(S,p1,principle3) :- left_standing(S,X), base_at(1,B), trig(B,S,ret(Q,X)),
                        holds(B,murderer(Q)).
% principialism2: global exception, retracting would yield a strictly lower
% expected utility (other actions being equal).
exc(S,p2,principle3) :- left_standing(S,X), retracted(S2,X), base_at(1,B),
                        util(S,B,U), util(S2,B,U2), U2 < U.

imp(S,p1) :- violated(S,P), P = (principle1;principle3), not exc(S,p1,P).
imp(S,p2) :- violated(S,P), P = (principle2;principle3), not exc(S,p2,P).
verdict(S,T,ok) :- sit(S), T = (p1;p2), not imp(S,T).
verdict(S,T,ko) :- imp(S,T).

% ---------- Consequentialism ---------------------------------------------
% c1: expected utility (step-1 base); c2: actual utility (environment).
ref(c1,B) :- base_at(1,B).
ref(c2,env).
best(T,M) :- ref(T,B), M = #max{ U,S : util(S,B,U) }.
verdict(S,T,ok) :- ref(T,B), util(S,B,U), best(T,U).
verdict(S,T,ko) :- ref(T,B), util(S,B,U), best(T,M), U < M.

#show type/3.
#show maintained/2.
#show retracted/2.
#show left_standing/2.
#show util/3.
#show verdict/3.
