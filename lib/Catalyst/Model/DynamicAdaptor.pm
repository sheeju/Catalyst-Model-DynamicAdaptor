package Catalyst::Model::DynamicAdaptor;

use Moose;
extends 'Catalyst::Model';
with 'CatalystX::Component::Traits';

use Module::Recursive::Require;

our $VERSION = 0.03;

my $app_class;

before COMPONENT => sub {
	$app_class = ref $_[1] || $_[1];
};

sub app_class { $app_class }

sub BUILD {
	my ($self, $args) = @_;
	my $class = $args->{catalyst_component_name};

    my $base_class = $args->{class};
    my $config     = $args->{config} || {};
    my $mrr_args   = $args->{mrr_args} || {};
    my $include_classes = $args->{include_classes} || {};

	my $mrr = Module::Recursive::Require->new($mrr_args);

	my $include_classes_join = join("|", @$include_classes);
	$mrr->add_filter(qr/^(?!($include_classes_join))/);

    my @plugins = $mrr->require_of($base_class);

    no strict 'refs';
    for my $plugin (@plugins) {
        my $plugin_short = $plugin;
        $plugin_short =~ s/^$base_class\:\://g;

        my %config = %{$config};
        my $obj ;
		if ( $plugin->can('new') ) {
			$obj = $plugin->new(\%config);

			#Set Catalyst Object to app method if it is defined
			if ( $plugin->can('c') ) {
				$obj->c($self->app_class);
			}
        }

        my $classname = "${class}::$plugin_short";

        if ( $plugin->can('new') ) { 
            *{"${classname}::ACCEPT_CONTEXT"} = sub {
                return $obj;
            };
        }
        else {
            *{"${classname}::ACCEPT_CONTEXT"} = sub {
                return $plugin;
            };

        }
    }

    return $self;
}

1;

=head1 NAME

Catalyst::Model::DynamicAdaptor - Dynamically load adaptor modules

=head1 VERSION

0.01

=head1 SYNOPSIS

 package App::Web::Model::Logic;

 use base qw/Catalyst::Model::DynamicAdaptor/;

 __PACKAGE__->config(
    class => 'App::Logic', # all modules under App::Logic::* will be loaded
    # config => { foo => 'foo' , bar => 'bar' }, # constractor parameter for each loading module )
    # mrr_args => { path => '/foo/bar' } # Module::Recursive::Require parameter.
 );

 1;

 package App::Web::Controller::Foo;

 sub foo : Local {
    my ( $self, $c ) = @_;

    # same as App::Logic::Foo->new->foo(); if you have App::Logic::Foo::new
    # same as App::Logic::Foo->foo(); # if you do not have App::Logic::Foo::new
    $c->model('Logic::Foo')->foo() ; 
 }

 1;

=head1 DESCRIPTION

 Load modules dynamicaly like L<Catalyst::Model::DBIC::Schema> does.


=head1 CHANGELOG
2013-08-26 - Fixed the issues in DynamicAdaptor and converted the package to Moose format
		   - Also added include_classes config to add only the Servlet's that we need instead of loading all the classes inside the base class


=head1 MODULE

=head2 new

constructor

=head1 AUTHOR

Tomohiro Teranishi <tomohiro.teranishi@gmail.com>
Sheeju Alex <sheejuec7@gmail.com>

=head1 THANKS

Tomohiro Teranishi

masaki

vkgtaro

hidek

hideden

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

