#!/usr/bin/env perl
package MooseX::Role::Parameterized;
use Moose qw/extends around confess/;
use Moose::Role ();
extends 'Moose::Exporter';

use MooseX::Role::Parameterized::Meta::Role::Parameterizable;

our $CURRENT_METACLASS;

__PACKAGE__->setup_import_methods(
    with_caller => ['parameter', 'role', 'method'],
    as_is       => ['has'],
);

sub parameter {
    my $caller = shift;
    my $names  = shift;

    $names = [$names] if !ref($names);

    for my $name (@$names) {
        Class::MOP::Class->initialize($caller)->add_parameter($name, @_);
    }
}

sub role {
    my $caller         = shift;
    my $role_generator = shift;
    Class::MOP::Class->initialize($caller)->role_generator($role_generator);
}

sub init_meta {
    my $self = shift;

    return Moose::Role->init_meta(@_,
        metaclass => 'MooseX::Role::Parameterized::Meta::Role::Parameterizable',
    );
}

# give role a (&) prototype
around _make_wrapper => sub {
    my $orig = shift;
    my ($self, $caller, $sub, $fq_name) = @_;

    if ($fq_name =~ /::role$/) {
        return sub (&) { $sub->($caller, @_) };
    }

    return $orig->(@_);
};

sub has {
    confess "has must be called within the role { ... } block."
        unless $CURRENT_METACLASS;

    my $names = shift;
    $names = [$names] if !ref($names);

    for my $name (@$names) {
        $CURRENT_METACLASS->add_attribute($name, @_);
    }
}

sub method {
    confess "method must be called within the role { ... } block."
        unless $CURRENT_METACLASS;

    my $caller = shift;
    my $name   = shift;
    my $body   = shift;

    my $method = Moose::Meta::Method->wrap(
        package_name => $caller,
        name         => $name,
        body         => $body,
    );

    $CURRENT_METACLASS->add_method($name => $method);
}

1;

