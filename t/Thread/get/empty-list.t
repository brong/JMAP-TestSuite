use jmaptest;

test {
  my ($self) = @_;

  my $account = $self->any_account;
  my $tester  = $account->tester;

  capability_check($tester,
    'urn:ietf:params:jmap:core',
    'urn:ietf:params:jmap:mail',
  ) or return;

  my $get_res = $tester->request([[
    "Thread/get" => { ids => [ ] },
  ]]);

  jcmp_deeply(
    $get_res->sentence_named('Thread/get')->arguments,
    {
      accountId => jstr($account->accountId),
      state => jstr(),
      list => [],
      notFound => [],
    },
    "Thread/get with empty ids list returns good response",
  );
};
