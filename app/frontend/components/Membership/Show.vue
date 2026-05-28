<template>
    <div class="show-page">
        <div class="hero">
            <TopoBackdrop />
            <div class="hero-inner">
                <div class="hero-top">
                    <div>
                        <div class="eyebrow">🪪 Afiliere</div>
                        <h1 class="title">Afilierea #{{ membership.id }}</h1>
                        <div class="subtitle">
                            <span v-if="membership.runner">
                                <a :href="`/runners/${membership.runner_id}`">{{ membership.runner.runner_name }} {{ membership.runner.surname }}</a>
                            </span>
                            <template v-if="membership.club">
                                <span class="dot">·</span>
                                <span>
                                    <a :href="`/clubs/${membership.club_id}`">{{ membership.club.club_name }}</a>
                                </span>
                            </template>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="stat-cards">
            <div class="stat-card">
                <div class="stat-icon">👤</div>
                <div class="stat-label">Sportiv</div>
                <div class="stat-value">
                    <a v-if="membership.runner" :href="`/runners/${membership.runner_id}`">{{ membership.runner.runner_name }} {{ membership.runner.surname }}</a>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">🏛</div>
                <div class="stat-label">Club</div>
                <div class="stat-value">
                    <a v-if="membership.club" :href="`/clubs/${membership.club_id}`">{{ membership.club.club_name }}</a>
                </div>
            </div>
            <div class="stat-card accent">
                <div class="stat-icon">🏅</div>
                <div class="stat-label">Rezultate</div>
                <div class="stat-value"><a :href="`/results?membership=${membership.id}`">{{ results.length }}</a></div>
            </div>
        </div>

        <div class="section">
            <button class="section-toggle" type="button" data-bs-toggle="collapse" data-bs-target="#resultsTable" aria-expanded="false" aria-controls="resultsTable">
                <span class="section-icon">🏅</span>
                <span class="section-title">Rezultate</span>
                <span class="section-meta">{{ results.length }}</span>
                <span class="section-caret">▾</span>
            </button>
            <div class="collapse" id="resultsTable">
                <div class="section-body">
                    <ResultsTable :elements="results" :hidden-columns="['full_name', 'club_name']" @order="orderResultTable"></ResultsTable>
                </div>
            </div>
        </div>

        <div class="footer-actions">
            <button class="btn btn-outline-secondary" @click="goBack">← Înapoi</button>
            <div v-if="isAdmin" class="action-group">
                <button class="btn btn-success btn-sm" @click="editElement(membership)">Editează</button>
                <button class="btn btn-danger btn-sm" @click="deleteMembership(membership.id)">Șterge</button>
            </div>
        </div>

        <Modal ref="modal" :membership="modalElement" :isNew="false" @save="updateElement" />
    </div>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import axios from '@/axios'
import Modal from './Modal.vue'
import ResultsTable from '../Result/Table.vue'
import TopoBackdrop from '../shared/TopoBackdrop.vue'
import { isAdmin } from '@/currentUser'

const membership = ref({})
const membershipId = ref("")
const results = ref([])
const resultSorting = ref({
    "sorting[sort_by]": "date",
    "sorting[direction]": "desc"
})

const modalElement = ref({})
const modal = ref(null)

onMounted(() => {
    membershipId.value = window.location.pathname.split('/').pop();
    getData();
    getResults();
})

async function getData() {
    const res = await axios.get(`/memberships/${membershipId.value}.json`)
    membership.value = res.data
}

async function getResults() {
    resultSorting.value["membership"] = membershipId.value
    const res = await axios.get('/results.json', { params: resultSorting.value })
    results.value = res.data;
}

function orderResultTable(sortKey) {
    orderTable(sortKey, resultSorting)
    getResults();
}

function editElement(membership) {
    modalElement.value = { ...membership }
    modal.value.show()
}

function updateElement(membershipData, done) {
    axios.patch(`/memberships/${membershipData.id}.json`, { membership: membershipData }).then(() => {
        getData();
        done()
    })
}

function deleteMembership(id) {
    if (confirm('Esti sigur ca vrei sa stergi această afiliere?')) {
        axios.delete(`/memberships/${id}`).then(() => {
            window.location = document.referrer || "/memberships"
        })
    }
}

function goBack() {
    window.location = document.referrer || "/memberships"
}

function orderTable(sortKey, filters) {
    const isCurrentSort = filters.value["sorting[sort_by]"] === sortKey;
    const currentDir = filters.value["sorting[direction]"];

    filters.value["sorting[direction]"] = (isCurrentSort && currentDir === "asc") ? "desc" : "asc";
    filters.value["sorting[sort_by]"] = sortKey;
}
</script>

<style scoped src="../shared/show.css"></style>
