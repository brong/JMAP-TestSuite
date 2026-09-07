use jmaptest;

# RFC 8620 section 3.6.2: "invalidArguments: One of the arguments is of the
# wrong type or otherwise invalid, or a required argument is missing."  Every
# standard method except Core/echo takes a required accountId, so a call that
# omits it must fail rather than be silently attributed to some default account.
#
# "accountNotFound: The accountId does not correspond to a valid account."
#
# The harness normally injects the account's accountId into every call, so
# these tests pass a reference to undef to suppress it (see JMAP::Tester's
# default_arguments).

test {
  my ($self) = @_;

  my $account = $self->any_account;
  my $tester  = $account->tester;

  capability_check($tester,
    'urn:ietf:params:jmap:core',
    'urn:ietf:params:jmap:mail',
  ) or return;

  my @methods = (
    [ 'Mailbox/get'   => {} ],
    [ 'Mailbox/query' => {} ],
    [ 'Email/get'     => { ids => [] } ],
    [ 'Email/query'   => {} ],
    [ 'Thread/get'    => { ids => [] } ],
  );

  subtest "missing accountId -> invalidArguments" => sub {
    for my $m (@methods) {
      my ($name, $args) = @$m;
      my $res = $tester->request([[
        $name => { %$args, accountId => \undef },
      ]]);
      ok($res->is_success, "$name request completed")
        or diag explain $res->response_payload;

      my $s = $res->sentence(0);
      is($s->name, 'error', "$name without accountId is an error")
        or diag explain $res->as_stripped_triples;
      jcmp_deeply(
        $s->arguments,
        superhashof({ type => 'invalidArguments' }),
        "$name without accountId -> invalidArguments",
      ) or diag explain $res->as_stripped_triples;
    }
  };

  subtest "unknown accountId -> accountNotFound" => sub {
    my $bogus = "no-such-account-" . join '', map { ('a'..'z')[rand 26] } 1..12;
    for my $m (@methods) {
      my ($name, $args) = @$m;
      my $res = $tester->request([[
        $name => { %$args, accountId => $bogus },
      ]]);
      ok($res->is_success, "$name request completed")
        or diag explain $res->response_payload;

      my $s = $res->sentence(0);
      is($s->name, 'error', "$name with unknown accountId is an error")
        or diag explain $res->as_stripped_triples;
      jcmp_deeply(
        $s->arguments,
        superhashof({ type => 'accountNotFound' }),
        "$name with unknown accountId -> accountNotFound",
      ) or diag explain $res->as_stripped_triples;
    }
  };

  subtest "Core/echo needs no accountId" => sub {
    my $res = $tester->request([[
      'Core/echo' => { hello => 'world', accountId => \undef },
    ]]);
    ok($res->is_success, "Core/echo request completed")
      or diag explain $res->response_payload;
    my $s = $res->sentence(0);
    is($s->name, 'Core/echo', "Core/echo without accountId succeeds")
      or diag explain $res->as_stripped_triples;
    jcmp_deeply($s->arguments, { hello => 'world' }, "echoed arguments exactly")
      or diag explain $res->as_stripped_triples;
  };
};
