use jmaptest;

# An accountId that names a real account on this server, but one this login
# cannot see, must be accountNotFound (RFC 8620 §3.6.2) -- indistinguishable
# from an id that does not exist at all. The other account comes from
# pristine_account, which every adapter provisions outside the caller's session.

attr pristine => 1;

test {
  my ($self) = @_;

  my $account = $self->any_account;
  my $other   = $self->pristine_account;

  capability_check($account->tester,
    'urn:ietf:params:jmap:core',
    'urn:ietf:params:jmap:mail',
    'urn:ietf:params:jmap:submission',
  ) or return;

  foreign_account_ok($account, $other, [
    [ 'EmailSubmission/get'          => { ids => [] } ],
    [ 'EmailSubmission/changes'      => { sinceState => '0' } ],
    [ 'EmailSubmission/query'        => {} ],
    [ 'EmailSubmission/queryChanges' => { sinceQueryState => '0' } ],
    [ 'EmailSubmission/set'          => {} ],
  ]);
};
