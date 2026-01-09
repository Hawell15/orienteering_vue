<template>
    <header class="navbar navbar-expand-lg navbar-light" style="background-color: #85de6a;">
        <div class="container-fluid">
            <a class="logo nav-link" href="/"><img class="header-logo" :src="logo" alt="Logo" /></a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarSupportedContent">
                <ul class="navbar-nav me-auto mb-2 mb-lg-0">
                    <li class="nav-item">
                        <a class="nav-link" href="#"></a>
                    </li>
                    <li class="nav-item dropdown">
                        <a class="nav-link dropdown-toggle show" href="#" id="navbarDropdown" role="button" data-bs-toggle="dropdown" aria-expanded="true">
                            Baza de Date
                        </a>
                        <ul class="dropdown-menu" aria-labelledby="navbarDropdown">
                            <a class="dropdown-item" href="/clubs">Cluburi</a>
                            <a class="dropdown-item" href="/runners">Sportivi</a>
                            <a class="dropdown-item" href="/competitions">Competitii</a>
                            <a class="dropdown-item" href="/groups">Grupe</a>
                            <a class="dropdown-item" href="/results">Rezultate</a>
                            <!-- <a class="dropdown-item" href="/entries">Indepliniri</a> -->
                            <a class="dropdown-item" href="/categories">Categorii</a>
                            <!-- <a class="dropdown-item" href="/competitions/ecn_ranking">Clasament National</a> -->
                            <!-- <a class="dropdown-item" href="/runners/license">Licențe</a> -->
                        </ul>
                    </li>
                </ul>
            </div>
        </div>
    </header>
</template>
<script setup>
import logo from '@/images/logo_fos.png'
</script>
<style scoped>
img.header-logo {
    height: 30px;
}
</style>
