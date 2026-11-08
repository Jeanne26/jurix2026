% =========================================================================
% Case study: an appeal deadline
% A client c asks a legal assistant a for the deadline to appeal a decision.
% Relying on an outdated rule, a believes it is 30 days, whereas it is
% actually 15 days, and learns the current rule before step 1.
% =========================================================================

decider(a).

% ---------- Belief bases and steps ---------------------------------------
base(ag0;ag1;env).
base_at(0,ag0). base_at(1,ag1).

holds(ag0, deadline(appeal,d30)).
holds(ag0, credible(deadline(appeal,d30),c)).

holds(ag1, deadline(appeal,d15)).
holds(ag1, credible(deadline(appeal,d30),c)).

holds(env, deadline(appeal,d15)).
holds(env, credible(deadline(appeal,d30),c)).

% ---------- Invariants ---------------------------------------------------
location(d15;d30).
shorter(d15,d30).

% ---------- Candidate decisions at step 1 ---------------------------------
% D0 = {inform}. The assertion is not retracted in D1^not_re = D0, and
% retracted in D1^re = D0 u {disconfirm}.
sit(not_re;re).
do(S, utter(a,c,0,inform(deadline(appeal,d30)))) :- sit(S).
do(re, utter(a,c,1,disconfirm(deadline(appeal,d30)))).

% ---------- Causal theory ------------------------------------------------
ev(B,S, utter(c,a,0,query(deadline(appeal,x)))) :- base(B), sit(S).

ev(B,S, corrected(c,X)) :- base(B), do(S, utter(a,c,_,disconfirm(X))),
                           not holds(B,too_late).
ev(B,S, relies(c,X))    :- base(B), do(S, utter(a,c,_,inform(X))),
                           holds(B, credible(X,c)),
                           not ev(B,S, corrected(c,X)).
ev(B,S, harm(c,missedDeadline)) :- ev(B,S, relies(c,deadline(appeal,L))),
                           holds(B, deadline(appeal,L2)), shorter(L2,L).

% ---------- Decision theory: answering choice -----------------------------
% gamma_ans <- query : < {inform(deadline(appeal,L)) | L} u {silence}, 1, 1 >
trig(B,S, ans) :- ev(B,S, utter(c,a,0,query(deadline(appeal,x)))).
offers(ans, utter(a,c,0,inform(deadline(appeal,L)))) :- location(L).
offers(ans, silence(a,c,0)).
bounds(ans,1,1).

% ---------- Utilities ----------------------------------------------------
utility(harm(c,missedDeadline), -3).

% ---------- Sanity checks ------------------------------------------------
% D0 is admissible at step 0, and the retraction is not available at step 0.
:- not admissible(ag0, not_re).
:- trig(ag0,_,ret(_,_)).
